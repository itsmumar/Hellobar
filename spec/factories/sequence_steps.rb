FactoryBot.define do
  factory :sequence_step do
    sequence(:name) { |i| "Step #{ i }" }

    delay 1

    association :sequence

    executable factory: :email
  end
end
