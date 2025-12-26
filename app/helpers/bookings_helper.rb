module BookingsHelper
  # 予約ステータスのバッジを返す
  # decoratorのdisplay_statusを使用して表示
  def booking_status_badge(booking)
    case booking.display_status
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

  # 予約詳細ページのアクションボタンを返す
  def booking_action_buttons(booking)
    if current_user.role_fp?
      fp_action_buttons(booking)
    else
      general_user_action_buttons(booking)
    end
  end

  private

  def fp_action_buttons(booking)
    return unless booking.status_pending?

    safe_join([
      link_to("承認", booking_confirm_path(booking),
              data: { turbo_method: :post, turbo_confirm: "この予約を承認しますか？" },
              class: "btn btn-success"),
      link_to("拒否", booking_reject_path(booking),
              data: { turbo_method: :post, turbo_confirm: "この予約を拒否しますか？" },
              class: "btn btn-danger")
    ])
  end

  def general_user_action_buttons(booking)
    return unless booking.display_cancellable?

    link_to("キャンセル", booking_path(booking),
            data: { turbo_method: :delete, turbo_confirm: "予約をキャンセルしますか？" },
            class: "btn btn-danger")
  end
end
