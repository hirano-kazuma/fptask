module BookingsHelper
  # 予約ステータスのバッジを返す
  def booking_status_badge(booking)
    case booking.status
    when "pending"
      content_tag(:span, "承認待ち", class: "badge bg-warning")
    when "confirmed"
      content_tag(:span, "確定", class: "badge bg-success")
    when "completed"
      content_tag(:span, "完了", class: "badge bg-info")
    when "cancelled"
      content_tag(:span, "キャンセル", class: "badge bg-secondary")
    when "rejected"
      content_tag(:span, "拒否", class: "badge bg-danger")
    end
  end

  # 予約の日時範囲をフォーマットして返す
  def booking_time_range(booking)
    start_time = booking.time_slot.start_time.strftime("%Y年%m月%d日 %H:%M")
    end_time = booking.time_slot.end_time.strftime("%H:%M")
    "#{start_time} - #{end_time}"
  end
end
