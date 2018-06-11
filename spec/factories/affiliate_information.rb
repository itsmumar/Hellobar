FactoryBot.define do
  factory :affiliate_information do
    user

    affiliate_identifier 'aid'
    visitor_identifier 'vid'
  end
end
