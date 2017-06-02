FactoryGirl.define do
  factory :identity do
    site
    provider 'mailchimp'
    credentials { { token: 'test' }.to_json }
    extra { { metadata: { api_endpoint: 'test' } }.to_json }

    trait :mailchimp do
      provider 'mailchimp'
      extra { Hash['metadata' => { 'api_endpoint' => 'https://us3.api.mailchimp.com' }] }
    end

    trait :mad_mimi do
      provider 'mad_mimi_form'
      credentials { Hash['token' => 'key'] }
    end

    trait :constantcontact do
      provider 'constantcontact'
      credentials { Hash['token' => 'key'] }
    end

    trait :icontact do
      provider 'icontact'
    end

    trait :vertical_response do
      provider 'vertical_response'
    end

    trait :my_emma do
      provider 'my_emma'
    end
  end
end
