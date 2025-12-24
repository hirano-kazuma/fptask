# frozen_string_literal: true

class TimeSlot < ApplicationRecord
  belongs_to :fp, class_name: "User"

  has_many :bookings, dependent: :restrict_with_error

  # 営業時間設定
  WEEKDAY_START_HOUR = 10 # 平日の開始時間
  WEEKDAY_END_HOUR = 18 # 平日の終了時間
  SATURDAY_START_HOUR = 11 # 土曜日の開始時間
  SATURDAY_END_HOUR = 15 # 土曜日の終了時間

  # エラーメッセージ定数
  DUPLICATE_TIME_SLOT_MESSAGE = "この時間帯は既に登録されています"

  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :start_time, uniqueness: { scope: :fp_id, message: DUPLICATE_TIME_SLOT_MESSAGE }
  validate :valid_day_of_week
  validate :valid_time_range
  validate :no_overlapping_slots

  before_destroy :check_active_bookings

  # スコープ
  scope :future, -> { where("start_time >= ?", Time.current) }
  scope :by_fp, ->(fp_id) { where(fp_id: fp_id) if fp_id.present? }

  # 予約可能かどうかを判定
  def available?
    bookings.where.not(status: [:cancelled, :rejected, :completed]).empty?
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

  # 営業日チェック（日曜は休業）
  def valid_day_of_week
    return if start_time.blank?

    if start_time.sunday?
      errors.add(:start_time, "日曜日は休業日です")
    end
  end

  # 営業時間チェック
  def valid_time_range
    return if start_time.blank?

    hour = start_time.hour
    min = start_time.min

    if start_time.saturday?
      # 土曜日: 11:00〜15:00（最後の枠は14:30〜15:00）
      unless hour >= SATURDAY_START_HOUR && (hour < SATURDAY_END_HOUR || (hour == 14 && min == 30))
        errors.add(:start_time, "土曜日は11:00〜15:00の間で指定してください")
      end
    else
      # 平日: 10:00〜18:00（最後の枠は17:30〜18:00）
      unless hour >= WEEKDAY_START_HOUR && (hour < WEEKDAY_END_HOUR || (hour == 17 && min == 30))
        errors.add(:start_time, "平日は10:00〜18:00の間で指定してください")
      end
    end
  end

  # 同じFPの既存の枠と時間が重複していないかチェック
  def no_overlapping_slots
    return if fp_id.blank? || start_time.blank? || end_time.blank?

    overlapping = TimeSlot.where(fp_id: fp_id)
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
