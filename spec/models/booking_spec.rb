# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Booking, type: :model do
  let(:fp) { User.create!(name: 'FP User', email: 'fp@example.com', password: 'password', role: :fp) }
  let(:general_user) { User.create!(name: 'General User', email: 'general@example.com', password: 'password', role: :general) }
  let(:time_slot) do
    TimeSlot.create!(
      fp: fp,
      start_time: Time.zone.parse("2025-12-20 10:00"),
      end_time: Time.zone.parse("2025-12-20 10:30")
    )
  end

  subject do
    Booking.new(
      time_slot: time_slot,
      user: general_user,
      description: "テスト予約",
      status: :pending
    )
  end

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

  describe 'no_duplicate_booking_for_time_slot' do
    context 'when there is no existing booking for the time slot' do
      it 'is valid' do
        expect(subject).to be_valid
      end
    end

    context 'when there is a pending booking for the same time slot' do
      before do
        Booking.create!(
          time_slot: time_slot,
          user: general_user,
          description: "既存の予約",
          status: :pending
        )
      end

      it 'is invalid' do
        expect(subject).to be_invalid
        expect(subject.errors[:base]).to include(Booking::DUPLICATE_BOOKING_MESSAGE)
      end
    end

    context 'when there is a confirmed booking for the same time slot' do
      before do
        Booking.create!(
          time_slot: time_slot,
          user: general_user,
          description: "既存の予約",
          status: :confirmed
        )
      end

      it 'is invalid' do
        expect(subject).to be_invalid
        expect(subject.errors[:base]).to include(Booking::DUPLICATE_BOOKING_MESSAGE)
      end
    end

    context 'when there is a cancelled booking for the same time slot' do
      before do
        Booking.create!(
          time_slot: time_slot,
          user: general_user,
          description: "既存の予約",
          status: :cancelled
        )
      end

      it 'is valid' do
        expect(subject).to be_valid
      end
    end

    context 'when there is a rejected booking for the same time slot' do
      before do
        Booking.create!(
          time_slot: time_slot,
          user: general_user,
          description: "既存の予約",
          status: :rejected
        )
      end

      it 'is valid' do
        expect(subject).to be_valid
      end
    end

    context 'when there is a completed booking for the same time slot' do
      before do
        Booking.create!(
          time_slot: time_slot,
          user: general_user,
          description: "既存の予約",
          status: :completed
        )
      end

      it 'is valid' do
        expect(subject).to be_valid
      end
    end
  end

  describe '#update_to_completed_if_past' do
    context 'when status is confirmed and end_time has passed' do
      let(:past_time_slot) do
        TimeSlot.create!(
          fp: fp,
          start_time: 2.hours.ago,
          end_time: 1.hour.ago
        )
      end

      let(:booking) do
        Booking.create!(
          time_slot: past_time_slot,
          user: general_user,
          description: "過去の予約",
          status: :confirmed
        )
      end

      it 'updates status to completed' do
        booking.update_to_completed_if_past
        expect(booking.reload.status).to eq('completed')
      end
    end

    context 'when status is confirmed but end_time has not passed' do
      let(:future_time_slot) do
        TimeSlot.create!(
          fp: fp,
          start_time: 1.hour.from_now,
          end_time: 1.hour.from_now + 30.minutes
        )
      end

      let(:booking) do
        Booking.create!(
          time_slot: future_time_slot,
          user: general_user,
          description: "未来の予約",
          status: :confirmed
        )
      end

      it 'does not update status' do
        booking.update_to_completed_if_past
        expect(booking.reload.status).to eq('confirmed')
      end
    end

    context 'when status is pending' do
      let(:past_time_slot) do
        TimeSlot.create!(
          fp: fp,
          start_time: 2.hours.ago,
          end_time: 1.hour.ago
        )
      end

      let(:booking) do
        Booking.create!(
          time_slot: past_time_slot,
          user: general_user,
          description: "過去の予約",
          status: :pending
        )
      end

      it 'does not update status' do
        booking.update_to_completed_if_past
        expect(booking.reload.status).to eq('pending')
      end
    end
  end
end
