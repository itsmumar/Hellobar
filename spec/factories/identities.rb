FactoryBot.define do
  factory :identity do
    site
    provider 'mailchimp'
    credentials { { token: 'test' }.to_json }
    extra { { metadata: { api_endpoint: 'test' } }.to_json }

    trait :aweber do
      provider 'aweber'
    end

    trait :active_campaign do
      provider 'active_campaign'
    end

    trait :createsend do
      provider 'createsend'
    end

    trait :constantcontact do
      provider 'constantcontact'
      credentials { Hash['token' => 'key'] }
    end

    trait :convert_kit do
      provider 'convert_kit'
    end

    trait :drip do
      provider 'drip'
      credentials { Hash['token' => 'token'] }
      extra do
        {
          'accounts' => [
            {
              'id' => '123'
            }
          ]
        }
      end
    end

    trait :get_response_api do
      provider 'get_response_api'
      credentials nil
      extra nil
      api_key 'api-key'
    end

    trait :icontact do
      provider 'icontact'
    end

    trait :infusionsoft do
      provider 'infusionsoft'
    end

    trait :iterable do
      provider 'iterable'
      credentials nil
      extra nil
      api_key 'api-key'
    end

    trait :mad_mimi_api do
      provider 'mad_mimi_api'
    end

    trait :mad_mimi_form do
      provider 'mad_mimi_form'
      credentials { Hash['token' => 'key'] }
    end

    trait :mailchimp do
      provider 'mailchimp'
      extra { Hash['metadata' => { 'api_endpoint' => 'https://us3.api.mailchimp.com' }] }
    end

    trait :maropost do
      provider 'maropost'
    end

    trait :my_emma do
      provider 'my_emma'
    end

    trait :verticalresponse do
      provider 'verticalresponse'
    end

    trait :vertical_response do
      provider 'vertical_response'
    end

    trait :webhooks do
      provider 'webhooks'
    end
  end
end
