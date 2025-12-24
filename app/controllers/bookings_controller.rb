class BookingsController < ApplicationController
  before_action :logged_in_user

  def index
    @bookings = load_bookings_for_current_user
    update_completed_bookings(@bookings)
  end

  def show
    if booking.nil?
      return redirect_to_not_found
    end

    @booking = booking
    @booking.update_to_completed_if_past
  end

  def new
    return unless validate_time_slot_for_booking

    @booking = current_user.bookings.build(time_slot: @time_slot)
  end

  def create
    return unless validate_time_slot_for_booking

    @booking = current_user.bookings.build(booking_params.merge(time_slot: @time_slot))
    if @booking.save
      redirect_to @booking, notice: "予約を申請しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    if booking.nil?
      return redirect_to_not_found
    end

    unless booking.status_cancellable?
      redirect_to bookings_path, alert: "完了済みの予約はキャンセルできません", status: :see_other
      return
    end

    booking.destroy
    redirect_to bookings_path, notice: "予約をキャンセルしました", status: :see_other
  end

  # FP用：予約を承認
  def confirm
    if booking.nil?
      return redirect_to_not_found
    end

    return unless can_modify_booking?("承認")

    if booking.update(status: :confirmed)
      redirect_to bookings_path, notice: "予約を承認しました"
    else
      redirect_to bookings_path, alert: "予約の承認に失敗しました"
    end
  end

  # FP用：予約を拒否
  def reject
    if booking.nil?
      return redirect_to_not_found
    end

    return unless can_modify_booking?("拒否")

    if booking.update(status: :rejected)
      redirect_to bookings_path, notice: "予約を拒否しました"
    else
      redirect_to bookings_path, alert: "予約の拒否に失敗しました"
    end
  end

  private

  # メモ化
  def booking
    @booking ||= if current_user.role_fp?
      # FP用：自分のTimeSlotに対する予約を取得
      Booking.joins(:time_slot)
             .where(time_slots: { fp_id: current_user.id })
             .includes(:time_slot, :user)
             .find_by(id: params[:id])
    else
      # 一般ユーザー用：自分の予約を取得
      current_user.bookings.includes(:time_slot, time_slot: :fp).find_by(id: params[:id])
    end
  end

  # 予約が見つからない場合のリダイレクト
  def redirect_to_not_found
    redirect_to bookings_path, alert: "予約が見つかりません", status: :see_other
  end

  def load_bookings_for_current_user
    if current_user.role_fp?
      # FP用：自分のTimeSlotに対する予約一覧
      Booking.joins(:time_slot)
             .where(time_slots: { fp_id: current_user.id })
             .includes(:time_slot, :user)
             .order(created_at: :desc)
    else
      # 一般ユーザー用：自分の予約一覧
      current_user.bookings.includes(:time_slot, time_slot: :fp).order(created_at: :desc)
    end
  end

  def update_completed_bookings(bookings)
    # confirmedステータスの予約のみをフィルタリングして更新
    confirmed_bookings = bookings.select(&:status_confirmed?)
    confirmed_bookings.each(&:update_to_completed_if_past)
  end

  def validate_time_slot_for_booking
    @time_slot = TimeSlot.find(params[:time_slot_id])

    # 過去の予約枠への予約申請を防ぐ
    if @time_slot.start_time < Time.current
      redirect_to time_slots_path, alert: "過去の予約枠には予約できません", status: :see_other
      return false
    end

    # 予約可能かどうかをチェック
    unless @time_slot.available?
      redirect_to time_slots_path, alert: "この予約枠は既に予約されています", status: :see_other
      return false
    end

    true
  rescue ActiveRecord::RecordNotFound
    redirect_to time_slots_path, alert: "予約枠が見つかりません", status: :see_other
    false
  end

  def booking_params
    params.require(:booking).permit(:description)
  end

  # FP用：予約の承認・拒否が可能かチェック
  def can_modify_booking?(action_name)
    # FP権限チェック
    unless current_user.role_fp?
      redirect_to bookings_path, alert: "FPユーザーのみ操作できます", status: :see_other
      return false
    end

    # 自分のTimeSlotに対する予約か確認
    unless booking.time_slot.fp_id == current_user.id
      redirect_to bookings_path, alert: "この予約を操作する権限がありません", status: :see_other
      return false
    end

    # 承認待ちの予約のみ操作可能
    unless booking.status_pending?
      redirect_to bookings_path, alert: "承認待ちの予約のみ#{action_name}できます", status: :see_other
      return false
    end

    true
  end
end
