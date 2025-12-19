# frozen_string_literal: true

module AuthenticationHelper
  def login_as(user)
    post session_path, params: { session: { email: user.email, password: 'password' } }
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelper, type: :request
end
