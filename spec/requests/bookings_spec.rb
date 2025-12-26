require 'rails_helper'

RSpec.describe "Bookings", type: :request do
  let(:fp) { create(:user, :fp) }
  let(:general_user) { create(:user, :general) }
  let(:other_user) { create(:user, :general) }

  let(:time_slot) { create(:time_slot, fp: fp, start_time: 1.day.from_now.change(hour: 10, min: 0), end_time: 1.day.from_now.change(hour: 10, min: 30)) }
  let(:past_time_slot) { create(:time_slot, fp: fp, start_time: 1.day.ago.change(hour: 10, min: 0), end_time: 1.day.ago.change(hour: 10, min: 30)) }

  describe "GET /bookings" do
    subject { get bookings_path }

    context "when logged in as general user" do
      before { login_as(general_user) }

      context "when user has bookings" do
        let!(:booking) { create(:booking, :pending, time_slot: time_slot, user: general_user, description: "テスト予約") }

        it "returns http success and displays user's bookings" do
          subject
          expect(response).to have_http_status(:success)
          expect(response.body).to include("テスト予約")
        end
      end

      context "when user has no bookings" do
        it "returns http success and displays empty message" do
          subject
          expect(response).to have_http_status(:success)
          expect(response.body).to include("予約がありません")
        end
      end
    end

    context "when logged in as FP user" do
      before { login_as(fp) }

      context "when FP has bookings for their time slots" do
        let!(:booking) { create(:booking, :pending, time_slot: time_slot, user: general_user, description: "FPへの予約") }

        it "returns http success and displays bookings for FP's time slots" do
          subject
          expect(response).to have_http_status(:success)
          expect(response.body).to include("FPへの予約")
        end
      end
    end

    context "when not logged in" do
      it "redirects to login page" do
        subject
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /bookings/:id" do
    let!(:booking) { create(:booking, :pending, time_slot: time_slot, user: general_user, description: "テスト予約詳細") }
    subject { get booking_path(booking) }

    context "when logged in as booking owner" do
      before { login_as(general_user) }

      it "returns http success and displays booking details" do
        subject
        expect(response).to have_http_status(:success)
        expect(response.body).to include("テスト予約詳細")
      end
    end

    context "when logged in as FP owner of time slot" do
      before { login_as(fp) }

      it "returns http success and displays booking details" do
        subject
        expect(response).to have_http_status(:success)
        expect(response.body).to include("テスト予約詳細")
      end
    end

    context "when logged in as different user" do
      before { login_as(other_user) }

      it "redirects to bookings index" do
        subject
        expect(response).to redirect_to(bookings_path)
        expect(flash[:alert]).to include("予約が見つかりません")
      end
    end
  end

  describe "GET /bookings/new" do
    let(:time_slot_id) { time_slot.id }
    subject { get new_booking_path(time_slot_id: time_slot_id) }

    context "when logged in as general user" do
      before { login_as(general_user) }

      context "with valid time_slot_id" do
        it "returns http success" do
          subject
          expect(response).to have_http_status(:success)
        end
      end

      context "with past time_slot" do
        let(:time_slot_id) { past_time_slot.id }

        it "redirects with alert" do
          subject
          expect(response).to redirect_to(time_slots_path)
          expect(flash[:alert]).to include("過去の予約枠には予約できません")
        end
      end

      context "with unavailable time_slot" do
        before { create(:booking, :pending, time_slot: time_slot, user: other_user, description: "既存の予約") }

        it "redirects with alert" do
          subject
          expect(response).to redirect_to(time_slots_path)
          expect(flash[:alert]).to include("この予約枠は既に予約されています")
        end
      end

      context "with invalid time_slot_id" do
        let(:time_slot_id) { 99999 }

        it "redirects with alert" do
          subject
          expect(response).to redirect_to(time_slots_path)
          expect(flash[:alert]).to include("予約枠が見つかりません")
        end
      end
    end

    context "when not logged in" do
      it "redirects to login page" do
        subject
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "POST /bookings" do
    let(:params) do
      {
        booking: { description: "新しい予約" },
        time_slot_id: time_slot.id
      }
    end
    subject { post bookings_path, params: params }

    context "when logged in as general user" do
      before { login_as(general_user) }

      context "with valid parameters" do
        it "creates a new booking with pending status, redirects to show page, and sets flash notice" do
          expect { subject }.to change(Booking, :count).by(1)
          expect(response).to redirect_to(Booking.last)
          expect(flash[:notice]).to include("予約を申請しました")
          expect(Booking.last.status).to eq('pending')
        end
      end

      context "with invalid parameters" do
        let(:params) { { booking: { description: "" }, time_slot_id: time_slot.id } }

        it "does not create a booking and renders new template" do
          expect { subject }.not_to change(Booking, :count)
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "with past time_slot" do
        let(:params) { { booking: { description: "過去の予約" }, time_slot_id: past_time_slot.id } }

        it "does not create a booking and redirects with alert" do
          expect { subject }.not_to change(Booking, :count)
          expect(response).to redirect_to(time_slots_path)
          expect(flash[:alert]).to include("過去の予約枠には予約できません")
        end
      end

      context "with unavailable time_slot" do
        before { create(:booking, :pending, time_slot: time_slot, user: other_user, description: "既存の予約") }

        let(:params) { { booking: { description: "重複予約" }, time_slot_id: time_slot.id } }

        it "does not create a booking and redirects with alert" do
          expect { subject }.not_to change(Booking, :count)
          expect(response).to redirect_to(time_slots_path)
          expect(flash[:alert]).to include("この予約枠は既に予約されています")
        end
      end
    end

    context "when not logged in" do
      it "redirects to login page" do
        subject
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "DELETE /bookings/:id" do
    let!(:booking) { create(:booking, :pending, time_slot: time_slot, user: general_user, description: "キャンセル可能な予約") }
    subject { delete booking_path(booking) }

    context "when logged in as booking owner" do
      before { login_as(general_user) }

      context "when booking is pending" do
        it "deletes the booking, redirects to bookings index, and sets flash notice" do
          expect { subject }.to change(Booking, :count).by(-1)
          expect(response).to redirect_to(bookings_path)
          expect(flash[:notice]).to include("予約をキャンセルしました")
        end
      end

      context "when booking is confirmed" do
        before { booking.update!(status: :confirmed) }

        it "deletes the booking" do
          expect { subject }.to change(Booking, :count).by(-1)
        end
      end

      context "when booking is completed" do
        before { booking.update!(status: :completed) }

        it "does not delete the booking and redirects with alert" do
          expect { subject }.not_to change(Booking, :count)
          expect(response).to redirect_to(bookings_path)
          expect(flash[:alert]).to include("完了済みの予約はキャンセルできません")
        end
      end
    end

    context "when logged in as different user" do
      before { login_as(other_user) }

      it "does not delete the booking and redirects with alert" do
        expect { subject }.not_to change(Booking, :count)
        expect(response).to redirect_to(bookings_path)
        expect(flash[:alert]).to include("予約が見つかりません")
      end
    end
  end

  describe "POST /bookings/:booking_id/confirm" do
    let!(:booking) { create(:booking, :pending, time_slot: time_slot, user: general_user, description: "承認待ちの予約") }
    subject { post booking_confirm_path(booking) }

    context "when logged in as FP owner" do
      before { login_as(fp) }

      it "updates booking status to confirmed, redirects to bookings index, and sets flash notice" do
        subject
        expect(booking.reload.status).to eq('confirmed')
        expect(response).to redirect_to(bookings_path)
        expect(flash[:notice]).to include("予約を承認しました")
      end
    end

    context "when logged in as general user" do
      before { login_as(general_user) }

      it "does not update booking status and redirects with alert" do
        expect { subject }.not_to change { booking.reload.status }
        expect(response).to redirect_to(bookings_path)
        expect(flash[:alert]).to include("FPユーザーのみ操作できます")
      end
    end

    context "when booking is already confirmed" do
      before do
        booking.update!(status: :confirmed)
        login_as(fp)
      end

      it "does not update booking status and redirects with alert" do
        expect { subject }.not_to change { booking.reload.status }
        expect(response).to redirect_to(bookings_path)
        expect(flash[:alert]).to include("承認待ちの予約のみ承認できます")
      end
    end
  end

  describe "POST /bookings/:booking_id/reject" do
    let!(:booking) { create(:booking, :pending, time_slot: time_slot, user: general_user, description: "拒否される予約") }
    let(:booking_id) { booking.id }
    subject { post booking_reject_path(booking_id) }

    context "when logged in as FP owner" do
      before { login_as(fp) }

      it "updates booking status to rejected, redirects to bookings index, and sets flash notice" do
        subject
        expect(booking.reload.status).to eq('rejected')
        expect(response).to redirect_to(bookings_path)
        expect(flash[:notice]).to include("予約を拒否しました")
      end
    end

    context "when logged in as general user" do
      before { login_as(general_user) }

      it "does not update booking status and redirects with alert" do
        expect { subject }.not_to change { booking.reload.status }
        expect(response).to redirect_to(bookings_path)
        expect(flash[:alert]).to include("FPユーザーのみ操作できます")
      end
    end

    context "when booking is already rejected" do
      before do
        booking.update!(status: :rejected)
        login_as(fp)
      end

      it "does not update booking status and redirects with alert" do
        expect { subject }.not_to change { booking.reload.status }
        expect(response).to redirect_to(bookings_path)
        expect(flash[:alert]).to include("承認待ちの予約のみ拒否できます")
      end
    end

    context "when logged in as different FP user" do
      let(:other_fp) { create(:user, :fp) }

      before { login_as(other_fp) }

      it "does not update booking status and redirects with alert" do
        expect { subject }.not_to change { booking.reload.status }
        expect(response).to redirect_to(bookings_path)
        expect(flash[:alert]).to include("予約が見つかりません")
      end
    end

    context "when booking does not exist" do
      let(:booking_id) { 99999 }

      before { login_as(fp) }

      it "redirects with alert" do
        subject
        expect(response).to redirect_to(bookings_path)
        expect(flash[:alert]).to include("予約が見つかりません")
      end
    end
  end
end
