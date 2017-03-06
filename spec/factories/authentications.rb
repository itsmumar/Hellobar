FactoryGirl.define do
  factory :authentication do
    user
    provider 'google_oauth2'
  end
end
