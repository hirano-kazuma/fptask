# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    let(:user) { User.new(name: 'Test User', email: 'test@example.com', password: 'password', role: :general) }

    it 'is valid with valid attributes' do
      expect(user).to be_valid
    end

    describe 'name' do
      it 'is invalid without a name' do
        user.name = nil
        expect(user).not_to be_valid
      end

      it 'is invalid with a name longer than 50 characters' do
        user.name = 'a' * 51
        expect(user).not_to be_valid
      end
    end

    describe 'email' do
      it 'is invalid without an email' do
        user.email = nil
        expect(user).not_to be_valid
      end

      it 'is invalid with an email longer than 255 characters' do
        user.email = 'a' * 244 + '@example.com'
        expect(user).not_to be_valid
      end

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

      it 'is invalid with a duplicate email (case insensitive)' do
        user.save!
        duplicate_user = User.new(name: 'Another User', email: 'TEST@example.com', password: 'password', role: :general)
        expect(duplicate_user).not_to be_valid
      end

      it 'is saved as lowercase' do
        user.email = 'TEST@EXAMPLE.COM'
        user.save!
        expect(user.reload.email).to eq('test@example.com')
      end
    end

    describe 'password' do
      it 'is invalid without a password' do
        user.password = nil
        user.password_confirmation = nil
        expect(user).not_to be_valid
      end

      it 'is invalid with a password shorter than 6 characters' do
        user.password = user.password_confirmation = 'a' * 5
        expect(user).not_to be_valid
      end
    end
  end

  describe 'role' do
    it 'can be general' do
      user = User.new(role: :general)
      expect(user.role_general?).to be true
    end

    it 'can be fp' do
      user = User.new(role: :fp)
      expect(user.role_fp?).to be true
    end
  end
end
