# TimeSlotの営業時間チェック用バリデータ
class TimeRangeValidator < ActiveModel::Validator
  # 営業時間設定
  WEEKDAY_START_HOUR = 10 # 平日の開始時間
  WEEKDAY_END_HOUR = 18   # 平日の終了時間
  SATURDAY_START_HOUR = 11 # 土曜日の開始時間
  SATURDAY_END_HOUR = 15   # 土曜日の終了時間

  def validate(record)
    return if record.start_time.blank?

    hour = record.start_time.hour
    min = record.start_time.min

    if record.start_time.saturday?
      validate_saturday_hours(record, hour, min)
    else
      validate_weekday_hours(record, hour, min)
    end
  end

  private

  def validate_saturday_hours(record, hour, min)
    # 土曜日: 11:00〜15:00（最後の枠は14:30〜15:00）
    return if hour >= SATURDAY_START_HOUR && (hour < SATURDAY_END_HOUR || (hour == 14 && min == 30))

    record.errors.add(:start_time, "土曜日は11:00〜15:00の間で指定してください")
  end

  def validate_weekday_hours(record, hour, min)
    # 平日: 10:00〜18:00（最後の枠は17:30〜18:00）
    return if hour >= WEEKDAY_START_HOUR && (hour < WEEKDAY_END_HOUR || (hour == 17 && min == 30))

    record.errors.add(:start_time, "平日は10:00〜18:00の間で指定してください")
  end
end
