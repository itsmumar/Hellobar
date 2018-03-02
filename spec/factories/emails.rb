FactoryGirl.define do
  factory :email do
    from_name 'Hello Bar'
    from_email 'dev@hellobar.com'
    subject 'Hello'
    body 'Test Campaign'
  end
end
