require 'rails_helper'

RSpec.describe TimeRangeValidator, type: :validator do
  let(:fp) { create(:user, :fp) }

  describe 'constants' do
    it { expect(described_class::WEEKDAY_START_HOUR).to eq(10) }
    it { expect(described_class::WEEKDAY_END_HOUR).to eq(18) }
    it { expect(described_class::SATURDAY_START_HOUR).to eq(11) }
    it { expect(described_class::SATURDAY_END_HOUR).to eq(15) }
  end

  describe '#validate' do
    subject { time_slot }

    context 'when start_time is blank' do
      let(:time_slot) { build(:time_slot, fp: fp, start_time: nil, end_time: nil) }

      it 'skips validation' do
        subject.valid?
        expect(subject.errors[:start_time]).not_to include("平日は10:00〜18:00の間で指定してください")
        expect(subject.errors[:start_time]).not_to include("土曜日は11:00〜15:00の間で指定してください")
      end
    end

    context 'when weekday (monday ~ friday)' do
      context 'when within business hours (10:00 ~ 17:30)' do
        let(:time_slot) { build(:time_slot, fp: fp, start_time: Time.zone.parse("2025-12-15 10:00"), end_time: Time.zone.parse("2025-12-15 10:30")) }

        it { is_expected.to be_valid }
      end

      context 'when last slot (17:30)' do
        let(:time_slot) { build(:time_slot, fp: fp, start_time: Time.zone.parse("2025-12-15 17:30"), end_time: Time.zone.parse("2025-12-15 18:00")) }

        it { is_expected.to be_valid }
      end

      context 'when before business hours (9:30)' do
        let(:time_slot) { build(:time_slot, fp: fp, start_time: Time.zone.parse("2025-12-15 09:30"), end_time: Time.zone.parse("2025-12-15 10:00")) }

        it { is_expected.to be_invalid }

        it 'has error message' do
          subject.valid?
          expect(subject.errors[:start_time]).to include("平日は10:00〜18:00の間で指定してください")
        end
      end

      context 'when after business hours (18:00)' do
        let(:time_slot) { build(:time_slot, fp: fp, start_time: Time.zone.parse("2025-12-15 18:00"), end_time: Time.zone.parse("2025-12-15 18:30")) }

        it { is_expected.to be_invalid }

        it 'has error message' do
          subject.valid?
          expect(subject.errors[:start_time]).to include("平日は10:00〜18:00の間で指定してください")
        end
      end
    end

    context 'when saturday' do
      context 'when within business hours (11:00 ~ 14:30)' do
        let(:time_slot) { build(:time_slot, fp: fp, start_time: Time.zone.parse("2025-12-13 11:00"), end_time: Time.zone.parse("2025-12-13 11:30")) }

        it { is_expected.to be_valid }
      end

      context 'when last slot (14:30)' do
        let(:time_slot) { build(:time_slot, fp: fp, start_time: Time.zone.parse("2025-12-13 14:30"), end_time: Time.zone.parse("2025-12-13 15:00")) }

        it { is_expected.to be_valid }
      end

      context 'when before business hours (10:30)' do
        let(:time_slot) { build(:time_slot, fp: fp, start_time: Time.zone.parse("2025-12-13 10:30"), end_time: Time.zone.parse("2025-12-13 11:00")) }

        it { is_expected.to be_invalid }

        it 'has error message' do
          subject.valid?
          expect(subject.errors[:start_time]).to include("土曜日は11:00〜15:00の間で指定してください")
        end
      end

      context 'when after business hours (15:00)' do
        let(:time_slot) { build(:time_slot, fp: fp, start_time: Time.zone.parse("2025-12-13 15:00"), end_time: Time.zone.parse("2025-12-13 15:30")) }

        it { is_expected.to be_invalid }

        it 'has error message' do
          subject.valid?
          expect(subject.errors[:start_time]).to include("土曜日は11:00〜15:00の間で指定してください")
        end
      end
    end
  end
end
