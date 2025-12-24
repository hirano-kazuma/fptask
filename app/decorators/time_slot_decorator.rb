module TimeSlotDecorator
  # カレンダー表示用のJSON形式に変換
  def to_calendar_json
    {
      id: id,
      start_time: start_time,
      end_time: end_time
    }.to_json
  end
end
