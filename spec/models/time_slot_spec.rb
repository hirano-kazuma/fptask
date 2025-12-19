require 'rails_helper'

RSpec.describe TimeSlot, type: :model do
  let(:fp) { User.create!(name: 'FP User', email: 'fp@example.com', password: 'password', role: :fp) }

  let(:valid_start_time) { Time.zone.parse("2025-12-15 10:00") }
  let(:valid_end_time) { Time.zone.parse("2025-12-15 10:30") }

  subject { TimeSlot.new(fp: fp, start_time: valid_start_time, end_time: valid_end_time) }

  describe 'associations' do
    it { is_expected.to belong_to(:fp).class_name('User') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:start_time) }
    it { is_expected.to validate_presence_of(:end_time) }
    it { is_expected.to validate_uniqueness_of(:start_time).scoped_to(:fp_id).with_message("この時間帯は既に登録されています") }
  end

  describe 'valid_day_of_week' do
    context 'when start_time is sunday' do
      let(:sunday_time) { Time.zone.parse("2025-12-14 10:00") }

      it 'is invalid and has error message' do
        time_slot = TimeSlot.new(fp: fp, start_time: sunday_time, end_time: sunday_time + 30.minutes)
        expect(time_slot).to be_invalid
        expect(time_slot.errors[:start_time]).to include("日曜日は休業日です")
      end
    end

    context 'when start_time is monday ~ saturday' do
      it 'is valid' do
        expect(subject).to be_valid
      end
    end
  end

  describe 'valid_time_range' do
    context 'when start_time weekdays (monday ~ friday)' do
      context 'when start_time is 10:00 ~ 18:00' do
        it 'is valid' do
          expect(subject).to be_valid
        end
      end

      context 'when start_time is 9:30 early' do
        let(:early_time) { Time.zone.parse("2025-12-15 09:30") }

        it 'it invalid and has error message' do
          time_slot = TimeSlot.new(fp: fp, start_time: early_time, end_time: early_time + 30.minutes)
          expect(time_slot).to be_invalid
          expect(time_slot.errors[:start_time]).to include("平日は10:00〜18:00の間で指定してください")
        end
      end

      context 'when start_time is 18:00 late' do
        let(:late_time) { Time.zone.parse("2025-12-15 18:00") }

        it 'it invalid and has error message' do
          time_slot = TimeSlot.new(fp: fp, start_time: late_time, end_time: late_time + 30.minutes)
          expect(time_slot).to be_invalid
          expect(time_slot.errors[:start_time]).to include("平日は10:00〜18:00の間で指定してください")
        end
      end
    end

    context 'when start_time is saturday' do
      context 'when start_time is 11:00 ~ 15:00' do
        let(:saturday_time) { Time.zone.parse("2025-12-13 11:00") }

        it 'is valid' do
          time_slot = TimeSlot.new(fp: fp, start_time: saturday_time, end_time: saturday_time + 30.minutes)
          expect(time_slot).to be_valid
        end
      end

      context 'when start_time is 10:30 early' do
        let(:early_time) { Time.zone.parse("2025-12-13 10:30") }

        it 'it invalid and has error message' do
          time_slot = TimeSlot.new(fp: fp, start_time: early_time, end_time: early_time + 30.minutes)
          expect(time_slot).to be_invalid
          expect(time_slot.errors[:start_time]).to include("土曜日は11:00〜15:00の間で指定してください")
        end
      end

      context 'when start_time is 15:00 late' do
        let(:late_time) { Time.zone.parse("2025-12-13 15:00") }

        it 'it invalid and has error message' do
          time_slot = TimeSlot.new(fp: fp, start_time: late_time, end_time: late_time + 30.minutes)
          expect(time_slot).to be_invalid
          expect(time_slot.errors[:start_time]).to include("土曜日は11:00〜15:00の間で指定してください")
        end
      end
    end
  end

  describe 'no_overlapping_slots' do
    context 'when there is some fp and time slot' do
      before do
        TimeSlot.create!(fp: fp, start_time: valid_start_time, end_time: valid_end_time)
      end

      it 'is invalid' do
        duplicate = TimeSlot.new(fp: fp, start_time: valid_start_time, end_time: valid_end_time)
        expect(duplicate).to be_invalid
        expect(duplicate.errors[:start_time]).to include("この時間帯は既に登録されています")
      end
    end

    context 'when there is same fp and different time slot' do
      let(:different_time) { Time.zone.parse("2025-12-15 11:00") }

      before do
        TimeSlot.create!(fp: fp, start_time: valid_start_time, end_time: valid_end_time)
      end

      it 'is valid' do
        time_slot = TimeSlot.new(fp: fp, start_time: different_time, end_time: different_time + 30.minutes)
        expect(time_slot).to be_valid
      end
    end

    context 'when there is different fp and same time slot' do
      let(:other_fp) { User.create!(name: 'Other FP', email: 'other@example.com', password: 'password', role: :fp) }

      before do
        # other_fp で 10:00〜10:30 の枠を作成
        TimeSlot.create!(fp: other_fp, start_time: valid_start_time, end_time: valid_end_time)
      end

      it 'is valid' do
        # fp（別のFP）で同じ時間の枠を作成 → 異なるFPなのでOK
        time_slot = TimeSlot.new(fp: fp, start_time: valid_start_time, end_time: valid_end_time)
        expect(time_slot).to be_valid
      end
    end
  end
end
