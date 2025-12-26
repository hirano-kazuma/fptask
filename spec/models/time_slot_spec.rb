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

  describe '#available?' do
    let(:time_slot) { create(:time_slot, fp: fp) }

    context 'when there are no bookings' do
      it 'returns true' do
        expect(time_slot.available?).to be true
      end
    end

    context 'when there is a pending booking' do
      before { create(:booking, :pending, time_slot: time_slot, user: create(:user, :general)) }

      it 'returns false' do
        expect(time_slot.available?).to be false
      end
    end

    context 'when there is a confirmed booking' do
      before { create(:booking, :confirmed, time_slot: time_slot, user: create(:user, :general)) }

      it 'returns false' do
        expect(time_slot.available?).to be false
      end
    end

    context 'when there is only a cancelled booking' do
      before { create(:booking, :cancelled, time_slot: time_slot, user: create(:user, :general)) }

      it 'returns true' do
        expect(time_slot.available?).to be true
      end
    end

    context 'when there is only a rejected booking' do
      before { create(:booking, :rejected, time_slot: time_slot, user: create(:user, :general)) }

      it 'returns true' do
        expect(time_slot.available?).to be true
      end
    end

    context 'when there is only a completed booking' do
      before { create(:booking, :completed, time_slot: time_slot, user: create(:user, :general)) }

      it 'returns true' do
        expect(time_slot.available?).to be true
      end
    end
  end

  describe '#to_available_hash' do
    let(:time_slot) { create(:time_slot, fp: fp) }

    it 'returns a hash with correct structure' do
      hash = time_slot.to_available_hash
      expect(hash).to include(:id, :start_time, :end_time, :fp_id, :fp_name, :available)
      expect(hash[:id]).to eq(time_slot.id)
      expect(hash[:start_time]).to eq(time_slot.start_time)
      expect(hash[:end_time]).to eq(time_slot.end_time)
      expect(hash[:fp_id]).to eq(time_slot.fp_id)
      expect(hash[:fp_name]).to eq(time_slot.fp.name)
      expect(hash[:available]).to eq(time_slot.available?)
    end
  end

  describe '#check_active_bookings' do
    let(:time_slot) { create(:time_slot, fp: fp) }

    context 'when there is a pending booking' do
      before { create(:booking, :pending, time_slot: time_slot, user: create(:user, :general)) }

      it 'prevents deletion' do
        expect { time_slot.destroy }.not_to change(TimeSlot, :count)
        expect(time_slot.errors[:base]).to include("承認済みまたは承認待ちの予約があるため削除できません")
      end
    end

    context 'when there is a confirmed booking' do
      before { create(:booking, :confirmed, time_slot: time_slot, user: create(:user, :general)) }

      it 'prevents deletion' do
        expect { time_slot.destroy }.not_to change(TimeSlot, :count)
        expect(time_slot.errors[:base]).to include("承認済みまたは承認待ちの予約があるため削除できません")
      end
    end

    context 'when there is a completed booking' do
      before { create(:booking, :completed, time_slot: time_slot, user: create(:user, :general)) }

      it 'prevents deletion' do
        expect { time_slot.destroy }.not_to change(TimeSlot, :count)
        expect(time_slot.errors[:base]).to include("承認済みまたは承認待ちの予約があるため削除できません")
      end
    end

    context 'when there is only a cancelled booking' do
      before { create(:booking, :cancelled, time_slot: time_slot, user: create(:user, :general)) }

      it 'allows deletion' do
        expect { time_slot.destroy }.to change(TimeSlot, :count).by(-1)
      end
    end

    context 'when there is only a rejected booking' do
      before { create(:booking, :rejected, time_slot: time_slot, user: create(:user, :general)) }

      it 'allows deletion' do
        expect { time_slot.destroy }.to change(TimeSlot, :count).by(-1)
      end
    end

    context 'when there are no bookings' do
      it 'allows deletion' do
        time_slot # 事前に作成してカウントを増やす
        expect { time_slot.destroy }.to change(TimeSlot, :count).by(-1)
      end
    end
  end

  describe 'scopes' do
    describe '.future' do
      let(:past_time) { Time.current.beginning_of_day.change(hour: 10, min: 0) - 1.day }
      let(:future_time) { Time.current.beginning_of_day.change(hour: 10, min: 0) + 1.day }
      let!(:past_time_slot) do
        create(:time_slot, fp: fp, start_time: past_time, end_time: past_time + 30.minutes)
      end
      let!(:future_time_slot) do
        create(:time_slot, fp: fp, start_time: future_time, end_time: future_time + 30.minutes)
      end

      it 'returns only future time slots' do
        future_slots = TimeSlot.future
        expect(future_slots).to include(future_time_slot)
        expect(future_slots).not_to include(past_time_slot)
      end
    end

    describe '.by_fp' do
      let(:other_fp) { create(:user, :fp) }
      let!(:fp_time_slot) { create(:time_slot, fp: fp) }
      let!(:other_fp_time_slot) { create(:time_slot, fp: other_fp) }

      context 'when fp_id is provided' do
        it 'returns only time slots for the specified FP' do
          fp_slots = TimeSlot.by_fp(fp.id)
          expect(fp_slots).to include(fp_time_slot)
          expect(fp_slots).not_to include(other_fp_time_slot)
        end
      end

      context 'when fp_id is nil' do
        it 'returns all time slots' do
          all_slots = TimeSlot.by_fp(nil)
          expect(all_slots).to include(fp_time_slot)
          expect(all_slots).to include(other_fp_time_slot)
        end
      end
    end
  end
end
