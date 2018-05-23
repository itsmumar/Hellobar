FactoryBot.define do
  factory :partner do
    name 'New Partner'
    sequence(:email) { |n| "partner#{n}@email.com" }
    sequence(:url) { |n| "http://partner-site#{n}.com" }
  end
end
