FactoryGirl.define do
  factory :site_element do
    rule
    type "Bar"
    element_subtype "announcement"
    
    trait :click_to_call do
      element_subtype "call"
      phone_number Faker::PhoneNumber.cell_phone
    end

    trait :traffic do
      element_subtype "traffic"
    end

    trait :email do
      element_subtype "email"
      contact_list
    end

    trait :twitter do
      element_subtype "social/tweet_on_twitter"
    end

    trait :facebook do
      element_subtype "social/like_on_facebook"
    end

    factory :modal_element do
      type "Modal"
    end

    factory :takeover_element do
      type "Takeover"
    end
  end
end
