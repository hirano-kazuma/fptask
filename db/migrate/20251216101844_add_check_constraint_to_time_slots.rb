class AddCheckConstraintToTimeSlots < ActiveRecord::Migration[8.1]
  def change
    # 開始時刻は00分または30分のみ許可
    add_check_constraint :time_slots, "MINUTE(start_time) IN (0, 30)", name: "check_start_time_minutes"

    # 終了時刻は00分または30分のみ許可
    add_check_constraint :time_slots, "MINUTE(end_time) IN (0, 30)", name: "check_end_time_minutes"

    # 終了時刻は開始時刻より後であること
    add_check_constraint :time_slots, "end_time > start_time", name: "check_end_time_after_start_time"
  end
end
