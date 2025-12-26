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
  validates :time_slot_id, uniqueness: { message: DUPLICATE_BOOKING_MESSAGE }

  scope :active, -> {
    joins(:time_slot)
      .where.not(status: [ :cancelled, :rejected, :completed ])
      .where("time_slots.end_time > ?", Time.current)
  }
  scope :cancellable, -> {
    joins(:time_slot)
      .where(status: [ :pending, :confirmed ])
      .where("time_slots.end_time > ?", Time.current)
  }

  # 確定済みの予約がend_timeを過ぎたら自動でcompletedに更新
  def update_to_completed_if_past
    return unless status_confirmed?
    return if time_slot.end_time > Time.current

    update(status: :completed)
  end

  # キャンセル可能かどうか（ステータス＋過去チェック）
  def cancellable?
    (status_pending? || status_confirmed?) && time_slot.end_time > Time.current
  end
end
