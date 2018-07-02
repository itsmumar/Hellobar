FactoryBot.define do
  factory :affiliate_information do
    user

    affiliate_identifier 'aid'
    visitor_identifier 'vid'
    conversion_identifier '1'
  end
end
