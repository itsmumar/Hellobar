FactoryGirl.define do
  factory :contact_list_log do
    contact_list
    sequence(:email) { |n| "log.email#{ n }@example.com" }
    name 'FirstName LastName'

    trait :completed do
      completed true
    end
  end
end
