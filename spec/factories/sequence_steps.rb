FactoryBot.define do
  factory :sequence_step do
    delay 1

    association :sequence

    executable factory: :email
  end
end
