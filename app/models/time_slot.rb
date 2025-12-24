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
end
