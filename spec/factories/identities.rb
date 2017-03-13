FactoryGirl.define do
  factory :identity do
    credentials { { token: 'test' }.to_json }
    extra { { metadata: { api_endpoint: 'test' } }.to_json }

    trait :mailchimp do
      provider 'mailchimp'
      extra { Hash['metadata' => { 'api_endpoint' => 'https://us3.api.mailchimp.com' }] }
    end

    trait :mad_mini do
      provider 'mad_mimi_form'
      credentials { Hash['token' => 'key'] }
    end
  end
end
