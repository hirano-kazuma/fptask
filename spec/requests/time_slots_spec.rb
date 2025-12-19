# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "TimeSlots", type: :request do
  let!(:fp_user) { User.create!(name: 'FP User', email: 'fp@example.com', password: 'password', role: :fp) }
  let!(:general_user) { User.create!(name: 'General User', email: 'general@example.com', password: 'password', role: :general) }
  let!(:other_fp) { User.create!(name: 'Other FP', email: 'otherfp@example.com', password: 'password', role: :fp) }

  # ログインヘルパー
  def login_as(user)
    post session_path, params: { session: { email: user.email, password: 'password' } }
  end

  describe "GET /time_slots" do
    subject { get time_slots_path }

    context "when logged in as FP user" do
      before { login_as(fp_user) }

      it "returns http success and displays page title" do
        subject
        expect(response).to have_http_status(:success)
        expect(response.body).to include("予約枠一覧")
      end
    end

    context "when not logged in" do
      it "redirects to login page" do
        subject
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when logged in as general user" do
      before { login_as(general_user) }

      it "redirects to root" do
        subject
        expect(response).to redirect_to(root_url)
      end
    end
  end

  describe "GET /time_slots/new" do
    subject { get new_time_slot_path }

    context "when logged in as FP user" do
      before { login_as(fp_user) }

      it "returns http success and displays page title" do
        subject
        expect(response).to have_http_status(:success)
        expect(response.body).to include("予約枠作成")
      end
    end

    context "when not logged in" do
      it "redirects to login page" do
        subject
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when logged in as general user" do
      before { login_as(general_user) }

      it "redirects to root" do
        subject
        expect(response).to redirect_to(root_url)
      end
    end
  end

  describe "POST /time_slots" do
    let(:params) { valid_time_slot_params }
    subject { post time_slots_path, params: params }

    let(:valid_time_slot_params) do
      {
        time_slot: {
          start_time: Time.zone.parse("2025-12-15 10:00"),
          end_time: Time.zone.parse("2025-12-15 10:30")
        }
      }
    end

    context "when logged in as FP user" do
      before { login_as(fp_user) }

      context "with valid parameters" do
        it "creates a new time slot with correct fp, redirects, and displays success message" do
          expect { subject }.to change(TimeSlot, :count).by(1)
          expect(TimeSlot.last.fp).to eq(fp_user)
          expect(response).to redirect_to(new_time_slot_path(date: "2025-12-15"))
          follow_redirect!
          expect(response.body).to include("予約枠を作成しました")
        end
      end

      context "with invalid parameters" do
        let(:params) do
          {
            time_slot: {
              start_time: nil,
              end_time: nil
            }
          }
        end

        it "does not create a new time slot and returns unprocessable entity status" do
          expect { subject }.not_to change(TimeSlot, :count)
          expect(response).to have_http_status(:unprocessable_entity)
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

  describe "GET /time_slots/:id" do
    let!(:time_slot) do
      TimeSlot.create!(
        fp: fp_user,
        start_time: Time.zone.parse("2025-12-15 10:00"),
        end_time: Time.zone.parse("2025-12-15 10:30")
      )
    end

    subject { get time_slot_path(time_slot) }

    context "when logged in as FP user (owner)" do
      before { login_as(fp_user) }

      it "returns http success and displays time slot details" do
        subject
        expect(response).to have_http_status(:success)
        expect(response.body).to include("2025年12月15日")
      end
    end

    context "when logged in as other FP user" do
      before { login_as(other_fp) }

      it "redirects to time slots index" do
        subject
        expect(response).to redirect_to(time_slots_path)
      end
    end

    context "when not logged in" do
      it "redirects to login page" do
        subject
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when accessing non-existent time slot" do
      before { login_as(fp_user) }

      it "redirects to time slots index with alert message" do
        get time_slot_path(99999)
        expect(response).to redirect_to(time_slots_path)
        follow_redirect!
        expect(response.body).to include("予約枠が見つかりません")
      end
    end
  end

  describe "GET /time_slots/:id/edit" do
    let!(:time_slot) do
      TimeSlot.create!(
        fp: fp_user,
        start_time: Time.zone.parse("2025-12-15 10:00"),
        end_time: Time.zone.parse("2025-12-15 10:30")
      )
    end

    subject { get edit_time_slot_path(time_slot) }

    context "when logged in as FP user (owner)" do
      before { login_as(fp_user) }

      it "returns http success and displays page title" do
        subject
        expect(response).to have_http_status(:success)
        expect(response.body).to include("予約枠編集")
      end
    end

    context "when logged in as other FP user" do
      before { login_as(other_fp) }

      it "redirects to time slots index" do
        subject
        expect(response).to redirect_to(time_slots_path)
      end
    end

    context "when not logged in" do
      it "redirects to login page" do
        subject
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when accessing non-existent time slot" do
      before { login_as(fp_user) }

      it "redirects to time slots index with alert message" do
        get edit_time_slot_path(99999)
        expect(response).to redirect_to(time_slots_path)
        follow_redirect!
        expect(response.body).to include("予約枠が見つかりません")
      end
    end
  end

  describe "PATCH /time_slots/:id" do
    let!(:time_slot) do
      TimeSlot.create!(
        fp: fp_user,
        start_time: Time.zone.parse("2025-12-15 10:00"),
        end_time: Time.zone.parse("2025-12-15 10:30")
      )
    end

    let(:params) { update_params }
    subject { patch time_slot_path(time_slot), params: params }

    let(:update_params) do
      {
        time_slot: {
          start_time: Time.zone.parse("2025-12-15 11:00"),
          end_time: Time.zone.parse("2025-12-15 11:30")
        }
      }
    end

    context "when logged in as FP user (owner)" do
      before { login_as(fp_user) }

      context "with valid parameters" do
        it "updates the time slot, redirects, and displays success message" do
          subject
          time_slot.reload
          expect(time_slot.start_time.hour).to eq(11)
          expect(response).to redirect_to(time_slot_path(time_slot))
          follow_redirect!
          expect(response.body).to include("予約枠を更新しました")
        end
      end

      context "with invalid parameters" do
        let(:params) do
          {
            time_slot: {
              start_time: nil,
              end_time: nil
            }
          }
        end

        it "does not update the time slot and returns unprocessable entity status" do
          expect { subject }.not_to change { time_slot.reload.start_time }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "when logged in as other FP user" do
      before { login_as(other_fp) }

      it "redirects to time slots index" do
        subject
        expect(response).to redirect_to(time_slots_path)
      end
    end

    context "when not logged in" do
      it "redirects to login page" do
        subject
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when accessing non-existent time slot" do
      before { login_as(fp_user) }

      it "redirects to time slots index with alert message" do
        patch time_slot_path(99999), params: update_params
        expect(response).to redirect_to(time_slots_path)
        follow_redirect!
        expect(response.body).to include("予約枠が見つかりません")
      end
    end
  end

  describe "DELETE /time_slots/:id" do
    let!(:time_slot) do
      TimeSlot.create!(
        fp: fp_user,
        start_time: Time.zone.parse("2025-12-15 10:00"),
        end_time: Time.zone.parse("2025-12-15 10:30")
      )
    end

    subject { delete time_slot_path(time_slot) }

    context "when logged in as FP user (owner)" do
      before { login_as(fp_user) }

      it "deletes the time slot, redirects, and displays success message" do
        expect { subject }.to change(TimeSlot, :count).by(-1)
        expect(response).to redirect_to(time_slots_path)
        follow_redirect!
        expect(response.body).to include("予約枠を削除しました")
      end
    end

    context "when logged in as other FP user" do
      before { login_as(other_fp) }

      it "does not delete the time slot and redirects to time slots index" do
        expect { subject }.not_to change(TimeSlot, :count)
        expect(response).to redirect_to(time_slots_path)
      end
    end

    context "when not logged in" do
      it "redirects to login page" do
        subject
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when accessing non-existent time slot" do
      before { login_as(fp_user) }

      it "redirects to time slots index with alert message" do
        delete time_slot_path(99999)
        expect(response).to redirect_to(time_slots_path)
        follow_redirect!
        expect(response.body).to include("予約枠が見つかりません")
      end
    end
  end
end
