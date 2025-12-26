FactoryBot.define do
  factory :booking do
    association :time_slot, factory: :time_slot
    association :user, factory: :user, role: :general
    description { "テスト予約" }
    status { :pending }

    trait :pending do
      status { :pending }
    end

    trait :confirmed do
      status { :confirmed }
    end

    trait :completed do
      status { :completed }
    end

    trait :cancelled do
      status { :cancelled }
    end

    trait :rejected do
      status { :rejected }
    end
  end
end
