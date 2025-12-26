# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Booking, type: :model do
  let(:fp) { create(:user, :fp) }
  let(:general_user) { create(:user, :general) }
  let(:base_date) { Time.zone.parse("2025-12-19") }
  let(:time_slot) { create(:time_slot, fp: fp, start_time: base_date.change(hour: 10), end_time: base_date.change(hour: 10, min: 30)) }

  subject { build(:booking, time_slot: time_slot, user: general_user) }

  describe 'associations' do
    it { is_expected.to belong_to(:time_slot) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:time_slot_id) }
    it { is_expected.to validate_presence_of(:user_id) }
    it { is_expected.to validate_presence_of(:description) }
  end

  describe 'enum' do
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, confirmed: 1, completed: 2, cancelled: 3, rejected: 4).with_prefix(true) }
  end

  describe 'scopes' do
    # スコープテスト用のTimeSlot（未来の日付を使用）
    let(:future_date) { Time.zone.parse("2025-12-29") }  # 月曜日（未来）
    let(:time_slots) do
      (10..14).map do |hour|
        create(:time_slot, fp: fp, start_time: future_date.change(hour: hour), end_time: future_date.change(hour: hour, min: 30))
      end
    end

    describe '.active' do
      let!(:pending_booking) { create(:booking, :pending, time_slot: time_slots[0], user: general_user) }
      let!(:confirmed_booking) { create(:booking, :confirmed, time_slot: time_slots[1], user: general_user) }
      let!(:cancelled_booking) { create(:booking, :cancelled, time_slot: time_slots[2], user: general_user) }
      let!(:rejected_booking) { create(:booking, :rejected, time_slot: time_slots[3], user: general_user) }
      let!(:completed_booking) { create(:booking, :completed, time_slot: time_slots[4], user: general_user) }

      it 'returns only pending and confirmed bookings' do
        expect(Booking.active).to contain_exactly(pending_booking, confirmed_booking)
      end
    end

    describe '.cancellable' do
      let!(:pending_booking) { create(:booking, :pending, time_slot: time_slots[0], user: general_user) }
      let!(:confirmed_booking) { create(:booking, :confirmed, time_slot: time_slots[1], user: general_user) }
      let!(:completed_booking) { create(:booking, :completed, time_slot: time_slots[2], user: general_user) }

      it 'returns only pending and confirmed bookings' do
        expect(Booking.cancellable).to contain_exactly(pending_booking, confirmed_booking)
      end
    end
  end

  # キャンセル可能かどうかを判定（ステータス＋過去チェック）
  describe '#cancellable?' do
    # 未来のtime_slotを使用
    let(:future_time) { Time.zone.parse("2025-12-29 10:00") }  # 月曜日（未来）
    let(:future_time_slot) { create(:time_slot, fp: fp, start_time: future_time, end_time: future_time + 30.minutes) }
    # 過去のtime_slotを使用
    let(:past_time) { Time.zone.parse("2025-12-19 10:00") }  # 金曜日（過去）
    let(:past_time_slot) { create(:time_slot, fp: fp, start_time: past_time, end_time: past_time + 30.minutes) }

    context 'when time_slot is in the future' do
      subject { booking.cancellable? }

      %i[pending confirmed].each do |status|
        context "when status is #{status}" do
          let(:booking) { create(:booking, status, time_slot: future_time_slot, user: general_user) }

          it { is_expected.to be true }
        end
      end

      %i[completed cancelled rejected].each do |status|
        context "when status is #{status}" do
          let(:booking) { create(:booking, status, time_slot: future_time_slot, user: general_user) }

          it { is_expected.to be false }
        end
      end
    end

    context 'when time_slot is in the past' do
      subject { booking.cancellable? }

      # 過去の場合はステータスに関係なくキャンセル不可
      %i[pending confirmed].each do |status|
        context "when status is #{status}" do
          let(:booking) { create(:booking, status, time_slot: past_time_slot, user: general_user) }

          it { is_expected.to be false }
        end
      end
    end
  end

  describe 'uniqueness validation for time_slot_id' do
    context 'when there is no existing booking' do
      it { is_expected.to be_valid }
    end

    context 'when there is an existing booking' do
      %i[pending confirmed cancelled rejected completed].each do |status|
        context "with #{status} booking" do
          before { create(:booking, status, time_slot: time_slot, user: general_user, description: "既存の予約") }

          it { is_expected.to be_invalid }

          it 'has duplicate error message on time_slot_id' do
            subject.valid?
            expect(subject.errors[:time_slot_id]).to include(Booking::DUPLICATE_BOOKING_MESSAGE)
          end
        end
      end
    end
  end

  describe '#update_to_completed_if_past' do
    # 固定の平日日付を使用（土曜日を回避）
    let(:past_time) { Time.zone.parse("2025-12-19 10:00") }      # 金曜日（過去）
    let(:future_time) { Time.zone.parse("2025-12-29 10:00") }    # 月曜日（未来）
    let(:past_time_slot) { create(:time_slot, fp: fp, start_time: past_time, end_time: past_time + 30.minutes) }
    let(:future_time_slot) { create(:time_slot, fp: fp, start_time: future_time, end_time: future_time + 30.minutes) }

    context 'when status is confirmed and end_time has passed' do
      let(:booking) { create(:booking, :confirmed, time_slot: past_time_slot, user: general_user) }

      it 'updates status to completed' do
        booking.update_to_completed_if_past
        expect(booking.reload).to be_status_completed
      end
    end

    context 'when status is confirmed but end_time has not passed' do
      let(:booking) { create(:booking, :confirmed, time_slot: future_time_slot, user: general_user) }

      it 'does not update status' do
        booking.update_to_completed_if_past
        expect(booking.reload).to be_status_confirmed
      end
    end

    context 'when status is pending (even if end_time has passed)' do
      let(:booking) { create(:booking, :pending, time_slot: past_time_slot, user: general_user) }

      it 'does not update status' do
        booking.update_to_completed_if_past
        expect(booking.reload).to be_status_pending
      end
    end
  end
end
