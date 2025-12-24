class TimeSlotsController < ApplicationController
  before_action :logged_in_user
  before_action :redirect_if_not_fp, except: [ :index ]

  def index
    if fp_user?
      set_existing_slots
    @time_slots = current_user.time_slots.order(:start_time)
    else
      # 一般ユーザー用：予約可能な枠一覧（未来の枠のみ）
      @fps = User.where(role: :fp).order(:name)
      selected_fp_id = params[:fp_id]&.to_i

      @time_slots = TimeSlot.includes(:bookings, :fp)
                            .future
                            .by_fp(selected_fp_id)
                            .order(:start_time)

      @selected_fp = @fps.find_by(id: selected_fp_id) if selected_fp_id
      @available_slots = @time_slots.map(&:to_available_hash)
      @existing_slots = []
    end
  end

  def show
    ensure_time_slot_exists
    nil if performed?
  end

  def new
    @time_slot = current_user.time_slots.build
    set_existing_slots
  end

  def create
    @time_slot = current_user.time_slots.build(time_slot_params)
    set_existing_slots
    if @time_slot.save
      # 作成した日付を渡して、同じ日付を自動選択
      date = @time_slot.start_time.strftime("%Y-%m-%d")
      redirect_to new_time_slot_path(date: date), notice: "予約枠を作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    ensure_time_slot_exists
    return if performed?
    set_existing_slots
  end

  def update
    ensure_time_slot_exists
    return if performed?
    set_existing_slots
    if time_slot.update(time_slot_params)
      redirect_to time_slot, notice: "予約枠を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    ensure_time_slot_exists
    return if performed?

    if time_slot.destroy
    redirect_to time_slots_path, notice: "予約枠を削除しました", status: :see_other
    else
      redirect_to time_slots_path, alert: time_slot.errors.full_messages.first, status: :see_other
    end
  end

  private

  # メモ化
  def time_slot
    @time_slot ||= current_user.time_slots.find_by(id: params[:id])
  end

  # レコードが見つからない場合の処理
  def ensure_time_slot_exists
    return if time_slot

    redirect_to time_slots_path, alert: "予約枠が見つかりません", status: :see_other
  end

  def set_existing_slots
    return unless fp_user? # FPユーザーのみ

    base_scope = current_user.time_slots.select(:id, :start_time, :end_time)
    @existing_slots = time_slot&.id ? base_scope.where.not(id: time_slot.id) : base_scope
  end

  def time_slot_params
    params.require(:time_slot).permit(:start_time, :end_time)
  end
end
