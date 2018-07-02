FactoryBot.define do
  factory :affiliate_commission do
    bill
    sequence(:identifier)
  end
end
