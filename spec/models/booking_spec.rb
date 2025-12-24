# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Booking, type: :model do
  let(:fp) { create(:user, :fp) }
  let(:general_user) { create(:user, :general) }
  let(:time_slot) { create(:time_slot, fp: fp, start_time: Time.zone.parse("2025-12-19 10:00"), end_time: Time.zone.parse("2025-12-19 10:30")) }

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
    describe '.active' do
      let(:time_slot_1) { create(:time_slot, fp: fp, start_time: Time.zone.parse("2025-12-19 10:00"), end_time: Time.zone.parse("2025-12-19 10:30")) }
      let(:time_slot_2) { create(:time_slot, fp: fp, start_time: Time.zone.parse("2025-12-19 11:00"), end_time: Time.zone.parse("2025-12-19 11:30")) }
      let(:time_slot_3) { create(:time_slot, fp: fp, start_time: Time.zone.parse("2025-12-19 12:00"), end_time: Time.zone.parse("2025-12-19 12:30")) }
      let(:time_slot_4) { create(:time_slot, fp: fp, start_time: Time.zone.parse("2025-12-19 13:00"), end_time: Time.zone.parse("2025-12-19 13:30")) }
      let(:time_slot_5) { create(:time_slot, fp: fp, start_time: Time.zone.parse("2025-12-19 14:00"), end_time: Time.zone.parse("2025-12-19 14:30")) }

      let!(:pending_booking) { create(:booking, :pending, time_slot: time_slot_1, user: general_user) }
      let!(:confirmed_booking) { create(:booking, :confirmed, time_slot: time_slot_2, user: general_user) }
      let!(:cancelled_booking) { create(:booking, :cancelled, time_slot: time_slot_3, user: general_user) }
      let!(:rejected_booking) { create(:booking, :rejected, time_slot: time_slot_4, user: general_user) }
      let!(:completed_booking) { create(:booking, :completed, time_slot: time_slot_5, user: general_user) }

      it 'returns only active bookings' do
        active_bookings = Booking.active
        expect(active_bookings).to include(pending_booking, confirmed_booking)
        expect(active_bookings).not_to include(cancelled_booking, rejected_booking, completed_booking)
      end
    end

    describe '.cancellable' do
      let(:time_slot_1) { create(:time_slot, fp: fp, start_time: Time.zone.parse("2025-12-19 10:00"), end_time: Time.zone.parse("2025-12-19 10:30")) }
      let(:time_slot_2) { create(:time_slot, fp: fp, start_time: Time.zone.parse("2025-12-19 11:00"), end_time: Time.zone.parse("2025-12-19 11:30")) }
      let(:time_slot_3) { create(:time_slot, fp: fp, start_time: Time.zone.parse("2025-12-19 12:00"), end_time: Time.zone.parse("2025-12-19 12:30")) }

      let!(:pending_booking) { create(:booking, :pending, time_slot: time_slot_1, user: general_user) }
      let!(:confirmed_booking) { create(:booking, :confirmed, time_slot: time_slot_2, user: general_user) }
      let!(:completed_booking) { create(:booking, :completed, time_slot: time_slot_3, user: general_user) }

      it 'returns only cancellable bookings' do
        cancellable_bookings = Booking.cancellable
        expect(cancellable_bookings).to include(pending_booking, confirmed_booking)
        expect(cancellable_bookings).not_to include(completed_booking)
      end
    end
  end

  describe '#status_cancellable?' do
    context 'when status is pending' do
      subject { create(:booking, :pending, time_slot: time_slot, user: general_user) }

      it 'returns true' do
        expect(subject.status_cancellable?).to be true
      end
    end

    context 'when status is confirmed' do
      subject { create(:booking, :confirmed, time_slot: time_slot, user: general_user) }

      it 'returns true' do
        expect(subject.status_cancellable?).to be true
      end
    end

    context 'when status is completed' do
      subject { create(:booking, :completed, time_slot: time_slot, user: general_user) }

      it 'returns false' do
        expect(subject.status_cancellable?).to be false
      end
    end

    context 'when status is cancelled' do
      subject { create(:booking, :cancelled, time_slot: time_slot, user: general_user) }

      it 'returns false' do
        expect(subject.status_cancellable?).to be false
      end
    end

    context 'when status is rejected' do
      subject { create(:booking, :rejected, time_slot: time_slot, user: general_user) }

      it 'returns false' do
        expect(subject.status_cancellable?).to be false
      end
    end
  end

  describe '#no_duplicate_booking_for_time_slot' do
    context 'when there is no existing booking for the time slot' do
      it 'is valid' do
        expect(subject).to be_valid
      end
    end

    context 'when there is a pending booking for the same time slot' do
      before { create(:booking, :pending, time_slot: time_slot, user: general_user, description: "既存の予約") }

      it 'is invalid' do
        expect(subject).to be_invalid
        expect(subject.errors[:base]).to include(Booking::DUPLICATE_BOOKING_MESSAGE)
      end
    end

    context 'when there is a confirmed booking for the same time slot' do
      before { create(:booking, :confirmed, time_slot: time_slot, user: general_user, description: "既存の予約") }

      it 'is invalid' do
        expect(subject).to be_invalid
        expect(subject.errors[:base]).to include(Booking::DUPLICATE_BOOKING_MESSAGE)
      end
    end

    context 'when there is a cancelled booking for the same time slot' do
      before { create(:booking, :cancelled, time_slot: time_slot, user: general_user, description: "既存の予約") }

      it 'is valid' do
        expect(subject).to be_valid
      end
    end

    context 'when there is a rejected booking for the same time slot' do
      before { create(:booking, :rejected, time_slot: time_slot, user: general_user, description: "既存の予約") }

      it 'is valid' do
        expect(subject).to be_valid
      end
    end

    context 'when there is a completed booking for the same time slot' do
      before { create(:booking, :completed, time_slot: time_slot, user: general_user, description: "既存の予約") }

      it 'is valid' do
        expect(subject).to be_valid
      end
    end
  end

  describe '#update_to_completed_if_past' do
    context 'when status is confirmed and end_time has passed' do
      let(:past_time) { Time.current.beginning_of_day.change(hour: 10, min: 0) - 1.day }
      let(:past_time_slot) { create(:time_slot, fp: fp, start_time: past_time, end_time: past_time + 30.minutes) }
      subject { create(:booking, :confirmed, time_slot: past_time_slot, user: general_user, description: "過去の予約") }

      it 'updates status to completed' do
        subject.update_to_completed_if_past
        expect(subject.reload.status).to eq('completed')
      end
    end

    context 'when status is confirmed but end_time has not passed' do
      let(:future_time) { Time.current.beginning_of_day.change(hour: 10, min: 0) + 1.day }
      let(:future_time_slot) { create(:time_slot, fp: fp, start_time: future_time, end_time: future_time + 30.minutes) }
      subject { create(:booking, :confirmed, time_slot: future_time_slot, user: general_user, description: "未来の予約") }

      it 'does not update status' do
        subject.update_to_completed_if_past
        expect(subject.reload.status).to eq('confirmed')
      end
    end

    context 'when status is pending' do
      let(:past_time) { Time.current.beginning_of_day.change(hour: 10, min: 0) - 1.day }
      let(:past_time_slot) { create(:time_slot, fp: fp, start_time: past_time, end_time: past_time + 30.minutes) }
      subject { create(:booking, :pending, time_slot: past_time_slot, user: general_user, description: "過去の予約") }

      it 'does not update status' do
        subject.update_to_completed_if_past
        expect(subject.reload.status).to eq('pending')
      end
    end
  end
end
