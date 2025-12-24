# frozen_string_literal: true

class TimeSlot < ApplicationRecord
  belongs_to :fp, class_name: "User"

  # 営業時間設定
  WEEKDAY_START_HOUR = 10 # 平日の開始時間
  WEEKDAY_END_HOUR = 18 # 平日の終了時間
  SATURDAY_START_HOUR = 11 # 土曜日の開始時間
  SATURDAY_END_HOUR = 15 # 土曜日の終了時間

  # エラーメッセージ定数
  DUPLICATE_TIME_SLOT_MESSAGE = "この時間帯は既に登録されています"

  # 営業時間チェック用バリデータ
  class TimeRangeValidator < ActiveModel::Validator
    def validate(record)
      return if record.start_time.blank?

      hour = record.start_time.hour
      min = record.start_time.min

      if record.start_time.saturday?
        # 土曜日: 11:00〜15:00（最後の枠は14:30〜15:00）
        unless hour >= SATURDAY_START_HOUR && (hour < SATURDAY_END_HOUR || (hour == 14 && min == 30))
          record.errors.add(:start_time, "土曜日は11:00〜15:00の間で指定してください")
        end
      else
        # 平日: 10:00〜18:00（最後の枠は17:30〜18:00）
        unless hour >= WEEKDAY_START_HOUR && (hour < WEEKDAY_END_HOUR || (hour == 17 && min == 30))
          record.errors.add(:start_time, "平日は10:00〜18:00の間で指定してください")
        end
      end
    end
  end

  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :start_time, uniqueness: { scope: :fp_id, message: DUPLICATE_TIME_SLOT_MESSAGE }
  validate :end_time_after_start_time
  validate :validate_day_of_week
  validate TimeRangeValidator.new
  validate :no_overlapping_slots

  # before_destroyをhas_manyより前に定義することで、コールバックが先に実行される
  before_destroy :check_active_bookings

  has_many :bookings, dependent: :destroy

  # スコープ
  scope :future, -> { where("start_time >= ?", Time.current) }
  scope :by_fp, ->(fp_id) { where(fp_id: fp_id) if fp_id.present? }

  # 予約可能かどうかを判定
  def available?
    bookings.active.empty?
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
                             .where(status: [:pending, :confirmed, :completed])
    if active_bookings.exists?
      errors.add(:base, "承認済みまたは承認待ちの予約があるため削除できません")
      throw :abort
    end
  end
end
