# frozen_string_literal: true

module BookingDecorator
  # 表示用のステータスを返す
  # confirmed かつ end_time が過去の場合は completed として表示
  def display_status
    if status_confirmed? && time_slot.end_time < Time.current
      "completed"
    else
      status
    end
  end

  # 表示上キャンセル可能かどうか
  def display_cancellable?
    cancellable?
  end
end
