# frozen_string_literal: true

class TimeSlot < ApplicationRecord
  belongs_to :fp, class_name: "User"

  # エラーメッセージ定数
  DUPLICATE_TIME_SLOT_MESSAGE = "この時間帯は既に登録されています"

  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :start_time, uniqueness: { scope: :fp_id, message: DUPLICATE_TIME_SLOT_MESSAGE }
  validate :end_time_after_start_time
  validate :validate_day_of_week
  validates_with TimeRangeValidator
  validate :no_overlapping_slots

  # before_destroyをhas_oneより前に定義することで、コールバックが先に実行される
  before_destroy :check_active_bookings

  # 1つのTimeSlotに1つのBooking（DBのユニーク制約と整合）
  has_one :booking, dependent: :destroy

  # スコープ
  scope :future, -> { where("start_time >= ?", Time.current) }
  scope :by_fp, ->(fp_id) { where(fp_id: fp_id) if fp_id.present? }

  # 予約可能かどうかを判定
  def available?
    booking.nil?
  end

  # 予約可能な枠の情報をハッシュで返す
  def to_available_hash
    {
      id: id,
      start_time: start_time,
      end_time: end_time,
      fp_id: fp_id,
      fp_name: fp.name,
      available: available?
    }
  end

  private

  # end_timeがstart_timeより後であることをチェック
  def end_time_after_start_time
    return if start_time.blank? || end_time.blank?

    return unless end_time <= start_time

    errors.add(:end_time, "終了時刻は開始時刻より後である必要があります")
  end

  # 営業日チェック（日曜は休業）
  def validate_day_of_week
    return if start_time.blank?
    return unless start_time.sunday?

    errors.add(:start_time, "日曜日は休業日です")
  end

  # 同じFPの既存の枠と時間が重複していないかチェック
  def no_overlapping_slots
    return if fp_id.blank? || start_time.blank? || end_time.blank?
    return unless fp

    overlapping = fp.time_slots
                          .where.not(id: id)
                          .where("start_time < ? AND end_time > ?", end_time, start_time)

    if overlapping.exists?
      errors.add(:base, DUPLICATE_TIME_SLOT_MESSAGE)
    end
  end

  # 承認済みまたは承認待ちの予約がある場合は削除を防ぐ
  def check_active_bookings
    # 承認済み、承認待ち、完了の予約をチェック
    # reloadして最新の状態を取得（キャッシュを回避）
    active_bookings = Booking.where(time_slot_id: id)
                             .where(status: [ :pending, :confirmed, :completed ])
    if active_bookings.exists?
      errors.add(:base, "承認済みまたは承認待ちの予約があるため削除できません")
      throw :abort
    end
  end
end
