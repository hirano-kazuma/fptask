# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  # shoulda-matchers を使ったバリデーションテスト
  describe 'validations' do
    # name
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(50) }

    # email
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_length_of(:email).is_at_most(255) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }

    # password
    it { is_expected.to validate_length_of(:password).is_at_least(6) }
    it { is_expected.to have_secure_password }
  end

  # shoulda-matchers を使った enum テスト
  describe 'enum' do
    it { is_expected.to define_enum_for(:role).with_values(general: 0, fp: 1).with_prefix(true) }
  end

  # shoulda-matchers では表現しにくいテスト（複数パターンのテスト）
  describe 'email format' do
    let(:user) { User.new(name: 'Test User', email: 'test@example.com', password: 'password', role: :general) }

    it 'is invalid with an invalid email format' do
      invalid_emails = %w[user@example,com user_at_foo.org user.name@example. foo@bar_baz.com foo@bar+baz.com]
      invalid_emails.each do |invalid_email|
        user.email = invalid_email
        expect(user).not_to be_valid, "#{invalid_email} should be invalid"
      end
    end

    it 'is valid with a valid email format' do
      valid_emails = %w[user@example.com USER@foo.COM A_US-ER@foo.bar.org first.last@foo.jp alice+bob@baz.cn]
      valid_emails.each do |valid_email|
        user.email = valid_email
        expect(user).to be_valid, "#{valid_email} should be valid"
      end
    end
  end

  # before_save のテスト（shoulda-matchers では表現できない）
  describe 'email downcase' do
    it 'is saved as lowercase' do
      user = User.create!(name: 'Test', email: 'TEST@EXAMPLE.COM', password: 'password', role: :general)
      expect(user.reload.email).to eq('test@example.com')
    end
  end
end
