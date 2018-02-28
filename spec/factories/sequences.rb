FactoryBot.define do
  factory :sequence do
    sequence(:name) { |i| "Sequence ##{ i }" }

    contact_list
  end
end
