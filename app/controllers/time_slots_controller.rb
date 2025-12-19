class TimeSlotsController < ApplicationController
  before_action :logged_in_user
  before_action :fp_user
  before_action :set_time_slot, only: %i[show edit update destroy]
  before_action :set_existing_slots, only: %i[index new create edit update]

  def index
    @time_slots = current_user.time_slots.order(:start_time)
  end

  def show
  end

  def new
    @time_slot = current_user.time_slots.build
  end

  def create
    @time_slot = current_user.time_slots.build(time_slot_params)
    if @time_slot.save
      # 作成した日付を渡して、同じ日付を自動選択
      date = @time_slot.start_time.strftime("%Y-%m-%d")
      redirect_to new_time_slot_path(date: date), notice: "予約枠を作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @time_slot.update(time_slot_params)
      redirect_to @time_slot, notice: "予約枠を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @time_slot.destroy
    redirect_to time_slots_path, notice: "予約枠を削除しました", status: :see_other
  end

  private

  def set_time_slot
    @time_slot = current_user.time_slots.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to time_slots_path, alert: "予約枠が見つかりません", status: :see_other
  end

  def set_existing_slots
    base_scope = current_user.time_slots.select(:id, :start_time, :end_time)
    @existing_slots = @time_slot ? base_scope.where.not(id: @time_slot.id) : base_scope
  end

  def time_slot_params
    params.require(:time_slot).permit(:start_time, :end_time)
  end
end
