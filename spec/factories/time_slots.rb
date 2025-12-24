FactoryBot.define do
  factory :time_slot do
    association :fp, factory: :user, strategy: :create, role: :fp
    start_time { Time.zone.parse("2025-12-15 10:00") }
    end_time { Time.zone.parse("2025-12-15 10:30") }

    trait :saturday do
      start_time { Time.zone.parse("2025-12-13 11:00") }
      end_time { Time.zone.parse("2025-12-13 11:30") }
    end

    trait :sunday do
      start_time { Time.zone.parse("2025-12-14 10:00") }
      end_time { Time.zone.parse("2025-12-14 10:30") }
    end
  end
end
