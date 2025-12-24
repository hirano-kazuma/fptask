FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "User #{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password" }
    role { :general }

    trait :fp do
      role { :fp }
    end

    trait :general do
      role { :general }
    end
  end
end
