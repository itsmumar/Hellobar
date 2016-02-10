FactoryGirl.define do
  factory :site_element do
    rule
    type "Bar"
    element_subtype "announcement"

    trait :click_to_call do
      element_subtype "call"
      phone_number Faker::PhoneNumber.cell_phone
    end

    factory :modal_element do
      type "Modal"
    end

    factory :takeover_element do
      type "Takeover"
    end
  end
end
