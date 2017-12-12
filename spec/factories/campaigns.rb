FactoryGirl.define do
  factory :campaign do
    site
    contact_list
    sequence(:name) { |i| "Campaign #{ i }" }
    from_name 'Hello Bar'
    from_email 'dev@hellobar.com'
    subject 'Hello'
    body 'Test Campaign'
  end
end
