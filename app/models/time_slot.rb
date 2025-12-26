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
