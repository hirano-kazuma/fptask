class BookingsController < ApplicationController
  before_action :logged_in_user
  before_action :set_booking, only: %i[show destroy confirm reject]

  def index
    if current_user.role_fp?
      # FP用：自分のTimeSlotに対する予約一覧
      @bookings = Booking.joins(:time_slot)
                         .where(time_slots: { fp_id: current_user.id })
                         .includes(:time_slot, :user)
                         .order(created_at: :desc)
      # 確定済みの予約がend_timeを過ぎていたら自動でcompletedに更新
      @bookings.each(&:update_to_completed_if_past)
    else
      # 一般ユーザー用：自分の予約一覧
      @bookings = current_user.bookings.includes(:time_slot, :time_slot => :fp).order(created_at: :desc)
      # 確定済みの予約がend_timeを過ぎていたら自動でcompletedに更新
      @bookings.each(&:update_to_completed_if_past)
    end
  end

  def show
    # 確定済みの予約がend_timeを過ぎていたら自動でcompletedに更新
    @booking.update_to_completed_if_past
  end

  def new
    @time_slot = TimeSlot.find(params[:time_slot_id])

    # 過去の予約枠への予約申請を防ぐ
    if @time_slot.start_time < Time.current
      redirect_to time_slots_path, alert: "過去の予約枠には予約できません", status: :see_other
      return
    end

    # 予約可能かどうかをチェック
    unless @time_slot.available?
      redirect_to time_slots_path, alert: "この予約枠は既に予約されています", status: :see_other
      return
    end

    @booking = current_user.bookings.build(time_slot: @time_slot)
  rescue ActiveRecord::RecordNotFound
    redirect_to time_slots_path, alert: "予約枠が見つかりません", status: :see_other
  end

  def create
    @time_slot = TimeSlot.find(params[:time_slot_id])

    # 過去の予約枠への予約申請を防ぐ
    if @time_slot.start_time < Time.current
      redirect_to time_slots_path, alert: "過去の予約枠には予約できません", status: :see_other
      return
    end

    # 予約可能かどうかをチェック
    unless @time_slot.available?
      redirect_to time_slots_path, alert: "この予約枠は既に予約されています", status: :see_other
      return
    end

    @booking = current_user.bookings.build(booking_params.merge(time_slot: @time_slot))
    if @booking.save
      redirect_to @booking, notice: "予約を申請しました"
    else
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "予約枠が見つかりません", status: :see_other
  end

  def destroy
    # 一般ユーザーは確定済み（confirmed）と承認待ち（pending）のみキャンセル可能
    unless @booking.status_confirmed? || @booking.status_pending?
      redirect_to bookings_path, alert: "完了済みの予約はキャンセルできません", status: :see_other
      return
    end

    @booking.destroy
    redirect_to bookings_path, notice: "予約をキャンセルしました", status: :see_other
  end

  # FP用：予約を承認
  def confirm
    return unless can_modify_booking?("承認")

    if @booking.update(status: :confirmed)
      redirect_to bookings_path, notice: "予約を承認しました"
    else
      redirect_to bookings_path, alert: "予約の承認に失敗しました"
    end
  end

  # FP用：予約を拒否
  def reject
    return unless can_modify_booking?("拒否")

    if @booking.update(status: :rejected)
      redirect_to bookings_path, notice: "予約を拒否しました"
    else
      redirect_to bookings_path, alert: "予約の拒否に失敗しました"
    end
  end

  private

  def set_booking
    if current_user.role_fp?
      # FP用：自分のTimeSlotに対する予約を取得
      @booking = Booking.joins(:time_slot)
                        .where(time_slots: { fp_id: current_user.id })
                        .includes(:time_slot, :user)
                        .find(params[:id])
    else
      # 一般ユーザー用：自分の予約を取得
      @booking = current_user.bookings.includes(:time_slot, :time_slot => :fp).find(params[:id])
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to bookings_path, alert: "予約が見つかりません", status: :see_other
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
    unless @booking.time_slot.fp_id == current_user.id
      redirect_to bookings_path, alert: "この予約を操作する権限がありません", status: :see_other
      return false
    end

    # 承認待ちの予約のみ操作可能
    unless @booking.status_pending?
      redirect_to bookings_path, alert: "承認待ちの予約のみ#{action_name}できます", status: :see_other
      return false
    end

    true
  end
end
