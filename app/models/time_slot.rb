# frozen_string_literal: true

class TimeSlot < ApplicationRecord
  belongs_to :fp, class_name: 'User'
  has_one :booking

  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :start_time, uniqueness: { scope: :fp_id, message: "この時間帯は既に登録されています" }
  validate :valid_day_of_week
  validate :valid_time_range
  validate :no_overlapping_slots

  # 予約済みかどうか
  def reserved?
    booking.present? && !booking.cancelled?
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
      unless hour >= 11 && (hour < 15 || (hour == 14 && min == 30))
        errors.add(:start_time, "土曜日は11:00〜15:00の間で指定してください")
      end
    else
      # 平日: 10:00〜18:00（最後の枠は17:30〜18:00）
      unless hour >= 10 && (hour < 18 || (hour == 17 && min == 30))
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
      errors.add(:base, "この時間帯は既に登録されています")
    end
  end
end
