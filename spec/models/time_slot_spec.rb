require 'rails_helper'

RSpec.describe TimeSlot, type: :model do
  let(:fp) { create(:user, :fp) }

  let(:valid_start_time) { Time.zone.parse("2025-12-15 10:00") }
  let(:valid_end_time) { Time.zone.parse("2025-12-15 10:30") }

  subject { build(:time_slot, fp: fp, start_time: valid_start_time, end_time: valid_end_time) }

  describe 'associations' do
    it { is_expected.to belong_to(:fp).class_name('User') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:start_time) }
    it { is_expected.to validate_presence_of(:end_time) }

    describe 'uniqueness of start_time scoped to fp_id' do
      it 'validates uniqueness' do
        create(:time_slot, fp: fp, start_time: valid_start_time, end_time: valid_end_time)
        duplicate = build(:time_slot, fp: fp, start_time: valid_start_time, end_time: valid_end_time)
        expect(duplicate).to be_invalid
        expect(duplicate.errors[:start_time]).to include("この時間帯は既に登録されています")
      end
    end
  end

  describe '#validate_day_of_week' do
    subject { time_slot.send(:validate_day_of_week) }

    context 'when start_time is sunday' do
      let(:time_slot) { build(:time_slot, :sunday, fp: fp) }

      it 'adds error to start_time' do
        subject
        expect(time_slot.errors[:start_time]).to include("日曜日は休業日です")
      end
    end

    context 'when start_time is monday ~ saturday' do
      let(:time_slot) { build(:time_slot, fp: fp, start_time: valid_start_time, end_time: valid_end_time) }

      it 'does not add error' do
        subject
        expect(time_slot.errors[:start_time]).to be_empty
      end
    end
  end

  describe 'validate_time_range' do
    subject { time_slot }

    context 'when start_time weekdays (monday ~ friday)' do
      context 'when start_time is 10:00 ~ 18:00' do
        let(:time_slot) { build(:time_slot, fp: fp, start_time: valid_start_time, end_time: valid_end_time) }

        it { is_expected.to be_valid }
      end

      context 'when start_time is 9:30 early' do
        let(:early_time) { Time.zone.parse("2025-12-15 09:30") }
        let(:time_slot) { build(:time_slot, fp: fp, start_time: early_time, end_time: early_time + 30.minutes) }

        it { is_expected.to be_invalid }

        it 'has error message' do
          subject.valid?
          expect(subject.errors[:start_time]).to include("平日は10:00〜18:00の間で指定してください")
        end
      end

      context 'when start_time is 18:00 late' do
        let(:late_time) { Time.zone.parse("2025-12-15 18:00") }
        let(:time_slot) { build(:time_slot, fp: fp, start_time: late_time, end_time: late_time + 30.minutes) }

        it { is_expected.to be_invalid }

        it 'has error message' do
          subject.valid?
          expect(subject.errors[:start_time]).to include("平日は10:00〜18:00の間で指定してください")
        end
      end
    end

    context 'when start_time is saturday' do
      context 'when start_time is 11:00 ~ 15:00' do
        let(:time_slot) { build(:time_slot, :saturday, fp: fp) }

        it { is_expected.to be_valid }
      end

      context 'when start_time is 10:30 early' do
        let(:early_time) { Time.zone.parse("2025-12-13 10:30") }
        let(:time_slot) { build(:time_slot, fp: fp, start_time: early_time, end_time: early_time + 30.minutes) }

        it { is_expected.to be_invalid }

        it 'has error message' do
          subject.valid?
          expect(subject.errors[:start_time]).to include("土曜日は11:00〜15:00の間で指定してください")
        end
      end

      context 'when start_time is 15:00 late' do
        let(:late_time) { Time.zone.parse("2025-12-13 15:00") }
        let(:time_slot) { build(:time_slot, fp: fp, start_time: late_time, end_time: late_time + 30.minutes) }

        it { is_expected.to be_invalid }

        it 'has error message' do
          subject.valid?
          expect(subject.errors[:start_time]).to include("土曜日は11:00〜15:00の間で指定してください")
        end
      end
    end
  end

  describe 'no_overlapping_slots' do
    context 'when fp_id is blank' do
      it 'skips validation without error' do
        time_slot = build(:time_slot, fp_id: nil, start_time: valid_start_time, end_time: valid_end_time)
        time_slot.valid?
        expect(time_slot.errors[:base]).not_to include("この時間帯は既に登録されています")
      end
    end

    context 'when fp is nil (fp_id exists but fp association is nil)' do
      it 'handles nil fp gracefully without error' do
        time_slot = build(:time_slot, fp_id: 99999, start_time: valid_start_time, end_time: valid_end_time)
        expect { time_slot.valid? }.not_to raise_error
      end
    end

    context 'when there is some fp and time slot' do
      before do
        create(:time_slot, fp: fp, start_time: valid_start_time, end_time: valid_end_time)
      end

      it 'is invalid' do
        duplicate = build(:time_slot, fp: fp, start_time: valid_start_time, end_time: valid_end_time)
        expect(duplicate).to be_invalid
        expect(duplicate.errors[:start_time]).to include("この時間帯は既に登録されています")
      end
    end

    context 'when there is same fp and different time slot' do
      let(:different_time) { Time.zone.parse("2025-12-15 11:00") }

      before do
        create(:time_slot, fp: fp, start_time: valid_start_time, end_time: valid_end_time)
      end

      it 'is valid' do
        time_slot = build(:time_slot, fp: fp, start_time: different_time, end_time: different_time + 30.minutes)
        expect(time_slot).to be_valid
      end
    end

    context 'when there is different fp and same time slot' do
      let(:other_fp) { create(:user, :fp) }

      before do
        # other_fp で 10:00〜10:30 の枠を作成
        create(:time_slot, fp: other_fp, start_time: valid_start_time, end_time: valid_end_time)
      end

      it 'is valid' do
        # fp（別のFP）で同じ時間の枠を作成 → 異なるFPなのでOK
        time_slot = build(:time_slot, fp: fp, start_time: valid_start_time, end_time: valid_end_time)
        expect(time_slot).to be_valid
      end
    end
  end
end
