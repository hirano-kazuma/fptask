class BookingsController < ApplicationController
  before_action :logged_in_user

  def index
    @bookings = bookings_for_current_user
  end

  def show
    return redirect_to_not_found if booking.nil?
    @booking = booking
  end

  def new
    result, error_message = validate_time_slot_for_booking
    return redirect_to time_slots_path, alert: error_message, status: :see_other unless result

    @booking = current_user.bookings.build(time_slot: time_slot)
  end

  def create
    result, error_message = validate_time_slot_for_booking
    return redirect_to time_slots_path, alert: error_message, status: :see_other unless result

    @booking = current_user.bookings.build(booking_params.merge(time_slot: time_slot))
    if @booking.save
      redirect_to @booking, notice: "予約を申請しました"
    elsif @booking.errors[:base].include?(Booking::DUPLICATE_BOOKING_MESSAGE)
      redirect_to time_slots_path, alert: "この予約枠は既に予約されています", status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    if booking.nil?
      return redirect_to_not_found
    end

    unless booking.cancellable?
      redirect_to bookings_path, alert: "この予約はキャンセルできません", status: :see_other
      return
    end

    booking.update!(status: :cancelled)
    redirect_to bookings_path, notice: "予約をキャンセルしました", status: :see_other
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

  def bookings_for_current_user
    bookings = if current_user.role_fp?
                 # FP用：自分のTimeSlotに対する予約一覧
                 Booking.joins(:time_slot).where(time_slots: { fp_id: current_user.id })
               else
                 # 一般ユーザー用：自分の予約一覧
                 current_user.bookings
               end
    bookings.includes(:time_slot, time_slot: :fp).order(created_at: :desc)
  end

  # @return [Boolean, String] バリデーション結果とエラーメッセージ
  def validate_time_slot_for_booking
    return [false, "予約枠が見つかりません"] if time_slot.nil?

    # 過去の予約枠への予約申請を防ぐ
    return [false, "過去の予約枠には予約できません"] if time_slot.start_time < Time.current

    # 予約可能かどうかをチェック
    return [false, "この予約枠は既に予約されています"] unless time_slot.available?

    [true, nil]
  end

  def time_slot
    @time_slot ||= TimeSlot.find_by(id: params[:time_slot_id])
  end

  def booking_params
    params.require(:booking).permit(:description)
  end
end
