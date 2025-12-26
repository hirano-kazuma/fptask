# frozen_string_literal: true

module Bookings
  class ConfirmsController < ApplicationController
    before_action :logged_in_user

    # POST /bookings/:booking_id/confirm
    def create
      result, error_message = validate_booking
      return redirect_to bookings_path, alert: error_message, status: :see_other unless result

      if booking.update(status: :confirmed)
        redirect_to bookings_path, notice: "予約を承認しました"
      else
        redirect_to bookings_path, alert: "予約の承認に失敗しました"
      end
    end

    private

    def booking
      @booking ||= Booking.joins(:time_slot)
                          .where(time_slots: { fp_id: current_user.id })
                          .find_by(id: params[:booking_id])
    end

    # @return [Boolean, String] バリデーション結果とエラーメッセージ
    def validate_booking
      return [ false, "予約が見つかりません" ] if booking.nil?
      return [ false, "FPユーザーのみ操作できます" ] unless current_user.role_fp?
      return [ false, "承認待ちの予約のみ承認できます" ] unless booking.status_pending?

      [ true, nil ]
    end
  end
end
