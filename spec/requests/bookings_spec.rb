require 'rails_helper'

RSpec.describe "Bookings", type: :request do
  let(:fp) { User.create!(name: 'FP User', email: 'fp@example.com', password: 'password', role: :fp) }
  let(:general_user) { User.create!(name: 'General User', email: 'general@example.com', password: 'password', role: :general) }
  let(:other_user) { User.create!(name: 'Other User', email: 'other@example.com', password: 'password', role: :general) }

  let(:time_slot) do
    TimeSlot.create!(
      fp: fp,
      start_time: 1.day.from_now.change(hour: 10, min: 0),
      end_time: 1.day.from_now.change(hour: 10, min: 30)
    )
  end

  let(:past_time_slot) do
    TimeSlot.create!(
      fp: fp,
      start_time: 1.day.ago.change(hour: 10, min: 0),
      end_time: 1.day.ago.change(hour: 10, min: 30)
    )
  end

  describe "GET /bookings" do
    context "when logged in as general user" do
      before { login_as(general_user) }

      context "when user has bookings" do
        let!(:booking) do
          Booking.create!(
            time_slot: time_slot,
            user: general_user,
            description: "テスト予約",
            status: :pending
          )
        end

        it "returns http success and displays user's bookings" do
          get bookings_path
          expect(response).to have_http_status(:success)
          expect(response.body).to include("テスト予約")
        end
      end

      context "when user has no bookings" do
        it "returns http success and displays empty message" do
          get bookings_path
          expect(response).to have_http_status(:success)
          expect(response.body).to include("予約がありません")
        end
      end
    end

    context "when logged in as FP user" do
      before { login_as(fp) }

      context "when FP has bookings for their time slots" do
        let!(:booking) do
          Booking.create!(
            time_slot: time_slot,
            user: general_user,
            description: "FPへの予約",
            status: :pending
          )
        end

        it "returns http success and displays bookings for FP's time slots" do
          get bookings_path
          expect(response).to have_http_status(:success)
          expect(response.body).to include("FPへの予約")
        end
      end
    end

    context "when not logged in" do
      it "redirects to login page" do
        get bookings_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /bookings/:id" do
    let!(:booking) do
      Booking.create!(
        time_slot: time_slot,
        user: general_user,
        description: "テスト予約詳細",
        status: :pending
      )
    end

    context "when logged in as booking owner" do
      it "returns http success and displays booking details" do
        login_as(general_user)
        get booking_path(booking)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("テスト予約詳細")
      end
    end

    context "when logged in as FP owner of time slot" do
      it "returns http success and displays booking details" do
        login_as(fp)
        get booking_path(booking)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("テスト予約詳細")
      end
    end

    context "when logged in as different user" do
      before { login_as(other_user) }

      it "redirects to bookings index" do
        get booking_path(booking)
        expect(response).to redirect_to(bookings_path)
        expect(flash[:alert]).to include("予約が見つかりません")
      end
    end
  end

  describe "GET /bookings/new" do
    context "when logged in as general user" do
      before { login_as(general_user) }

      context "with valid time_slot_id" do
        it "returns http success" do
          get new_booking_path(time_slot_id: time_slot.id)
          expect(response).to have_http_status(:success)
        end
      end

      context "with past time_slot" do
        it "redirects with alert" do
          get new_booking_path(time_slot_id: past_time_slot.id)
          expect(response).to redirect_to(time_slots_path)
          expect(flash[:alert]).to include("過去の予約枠には予約できません")
        end
      end

      context "with unavailable time_slot" do
        before do
          Booking.create!(
            time_slot: time_slot,
            user: other_user,
            description: "既存の予約",
            status: :pending
          )
        end

        it "redirects with alert" do
          get new_booking_path(time_slot_id: time_slot.id)
          expect(response).to redirect_to(time_slots_path)
          expect(flash[:alert]).to include("この予約枠は既に予約されています")
        end
      end

      context "with invalid time_slot_id" do
        it "redirects with alert" do
          get new_booking_path(time_slot_id: 99999)
          expect(response).to redirect_to(time_slots_path)
          expect(flash[:alert]).to include("予約枠が見つかりません")
        end
      end
    end

    context "when not logged in" do
      it "redirects to login page" do
        get new_booking_path(time_slot_id: time_slot.id)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "POST /bookings" do
    context "when logged in as general user" do
      before { login_as(general_user) }

      context "with valid parameters" do
        let(:valid_params) do
          {
            booking: {
              description: "新しい予約"
            },
            time_slot_id: time_slot.id
          }
        end

        it "creates a new booking with pending status, redirects to show page, and sets flash notice" do
          expect {
            post bookings_path, params: valid_params
          }.to change(Booking, :count).by(1)
          expect(response).to redirect_to(Booking.last)
          expect(flash[:notice]).to include("予約を申請しました")
          expect(Booking.last.status).to eq('pending')
        end
      end

      context "with invalid parameters" do
        let(:invalid_params) do
          {
            booking: {
              description: ""
            },
            time_slot_id: time_slot.id
          }
        end

        it "does not create a booking and renders new template" do
          expect {
            post bookings_path, params: invalid_params
          }.not_to change(Booking, :count)
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "with past time_slot" do
        let(:params) do
          {
            booking: {
              description: "過去の予約"
            },
            time_slot_id: past_time_slot.id
          }
        end

        it "does not create a booking and redirects with alert" do
          expect {
            post bookings_path, params: params
          }.not_to change(Booking, :count)
          expect(response).to redirect_to(time_slots_path)
          expect(flash[:alert]).to include("過去の予約枠には予約できません")
        end
      end

      context "with unavailable time_slot" do
        before do
          Booking.create!(
            time_slot: time_slot,
            user: other_user,
            description: "既存の予約",
            status: :pending
          )
        end

        let(:params) do
          {
            booking: {
              description: "重複予約"
            },
            time_slot_id: time_slot.id
          }
        end

        it "does not create a booking and redirects with alert" do
          expect {
            post bookings_path, params: params
          }.not_to change(Booking, :count)
          expect(response).to redirect_to(time_slots_path)
          expect(flash[:alert]).to include("この予約枠は既に予約されています")
        end
      end
    end

    context "when not logged in" do
      it "redirects to login page" do
        post bookings_path, params: { booking: { description: "テスト" }, time_slot_id: time_slot.id }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "DELETE /bookings/:id" do
    let!(:booking) do
      Booking.create!(
        time_slot: time_slot,
        user: general_user,
        description: "キャンセル可能な予約",
        status: :pending
      )
    end

    context "when logged in as booking owner" do
      before { login_as(general_user) }

      context "when booking is pending" do
        it "deletes the booking, redirects to bookings index, and sets flash notice" do
          expect {
            delete booking_path(booking)
          }.to change(Booking, :count).by(-1)
          expect(response).to redirect_to(bookings_path)
          expect(flash[:notice]).to include("予約をキャンセルしました")
        end
      end

      context "when booking is confirmed" do
        before { booking.update!(status: :confirmed) }

        it "deletes the booking" do
          expect {
            delete booking_path(booking)
          }.to change(Booking, :count).by(-1)
        end
      end

      context "when booking is completed" do
        before { booking.update!(status: :completed) }

        it "does not delete the booking and redirects with alert" do
          expect {
            delete booking_path(booking)
          }.not_to change(Booking, :count)
          expect(response).to redirect_to(bookings_path)
          expect(flash[:alert]).to include("完了済みの予約はキャンセルできません")
        end
      end
    end

    context "when logged in as different user" do
      it "does not delete the booking and redirects with alert" do
        login_as(other_user)
        expect {
          delete booking_path(booking)
        }.not_to change(Booking, :count)
        expect(response).to redirect_to(bookings_path)
        expect(flash[:alert]).to include("予約が見つかりません")
      end
    end
  end

  describe "PATCH /bookings/:id/confirm" do
    let!(:booking) do
      Booking.create!(
        time_slot: time_slot,
        user: general_user,
        description: "承認待ちの予約",
        status: :pending
      )
    end

    context "when logged in as FP owner" do
      it "updates booking status to confirmed, redirects to bookings index, and sets flash notice" do
        login_as(fp)
        patch confirm_booking_path(booking)
        expect(booking.reload.status).to eq('confirmed')
        expect(response).to redirect_to(bookings_path)
        expect(flash[:notice]).to include("予約を承認しました")
      end
    end

    context "when logged in as general user" do
      it "does not update booking status and redirects with alert" do
        login_as(general_user)
        expect {
          patch confirm_booking_path(booking)
        }.not_to change { booking.reload.status }
        expect(response).to redirect_to(bookings_path)
        expect(flash[:alert]).to include("FPユーザーのみ操作できます")
      end
    end

    context "when booking is already confirmed" do
      it "does not update booking status and redirects with alert" do
        booking.update!(status: :confirmed)
        login_as(fp)
        expect {
          patch confirm_booking_path(booking)
        }.not_to change { booking.reload.status }
        expect(response).to redirect_to(bookings_path)
        expect(flash[:alert]).to include("承認待ちの予約のみ承認できます")
      end
    end
  end

  describe "PATCH /bookings/:id/reject" do
    let!(:booking) do
      Booking.create!(
        time_slot: time_slot,
        user: general_user,
        description: "拒否される予約",
        status: :pending
      )
    end

    context "when logged in as FP owner" do
      it "updates booking status to rejected, redirects to bookings index, and sets flash notice" do
        login_as(fp)
        patch reject_booking_path(booking)
        expect(booking.reload.status).to eq('rejected')
        expect(response).to redirect_to(bookings_path)
        expect(flash[:notice]).to include("予約を拒否しました")
      end
    end

    context "when logged in as general user" do
      it "does not update booking status and redirects with alert" do
        login_as(general_user)
        expect {
          patch reject_booking_path(booking)
        }.not_to change { booking.reload.status }
        expect(response).to redirect_to(bookings_path)
        expect(flash[:alert]).to include("FPユーザーのみ操作できます")
      end
    end
  end
end
