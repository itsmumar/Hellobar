FactoryGirl.define do
  factory :campaign do
    site
    contact_list
    sequence(:name) { |i| "Email Campaign #{ i }" }
    from_name 'Hello Bar'
    from_email 'dev@hellobar.com'
    subject 'Hello'
    body 'Test Email Campaign'
  end
end
