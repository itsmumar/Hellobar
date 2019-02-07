FactoryBot.define do
  factory :email do
    from_name 'Hello Bar'
    from_email 'dev@hellobar.com'
    subject 'Hello'
    body 'Test Campaign'
    plain_body 'Plain Body'
    preview_text 'Preview Text'
    site
  end
end
