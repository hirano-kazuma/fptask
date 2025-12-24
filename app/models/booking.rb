# frozen_string_literal: true

class Booking < ApplicationRecord
  belongs_to :time_slot
  belongs_to :user

  enum :status, {
    pending: 0,      # 承認待ち
    confirmed: 1,     # 確定
    completed: 2,     # 完了
    cancelled: 3,     # キャンセル
    rejected: 4       # 拒否
  }, prefix: true

  # エラーメッセージ定数
  DUPLICATE_BOOKING_MESSAGE = "この時間帯は既に予約されています"

  validates :time_slot_id, presence: true
  validates :user_id, presence: true
  validates :description, presence: true
  validate :no_duplicate_booking_for_time_slot

  # 確定済みの予約がend_timeを過ぎたら自動でcompletedに更新
  def update_to_completed_if_past
    return unless status_confirmed?
    return if time_slot.end_time > Time.current

    update(status: :completed)
  end

  private

  # 同じTimeSlotへの重複予約を防ぐ（キャンセル済み・拒否済み・完了済みは除く）
  def no_duplicate_booking_for_time_slot
    return if time_slot_id.blank?

    existing_booking = Booking.where(time_slot_id: time_slot_id)
                              .where.not(id: id)
                              .where.not(status: [:cancelled, :rejected, :completed])

    if existing_booking.exists?
      errors.add(:base, DUPLICATE_BOOKING_MESSAGE)
    end
  end
end
