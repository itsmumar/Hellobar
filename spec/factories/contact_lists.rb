FactoryGirl.define do
  factory :contact_list do
    transient do
      list_id 1
    end

    site
    name 'My List'
    data { Hash['remote_id' => list_id] }

    trait :with_tags do
      data { Hash['tags' => ['id1', 'id2'], 'remote_id' => list_id] }
    end

    trait :aweber do
      identity { create :identity, :aweber, site: site }
    end

    trait :active_campaign do
      identity { create :identity, :active_campaign, site: site }
    end

    trait :createsend do
      identity { create :identity, :createsend, site: site }
    end

    trait :constantcontact do
      identity { create :identity, :constantcontact, site: site }
    end

    trait :convert_kit do
      identity { create :identity, :convert_kit, site: site }
    end

    trait :drip do
      identity { create :identity, :drip, site: site }
      data { Hash['remote_id' => list_id] }
    end

    trait :get_response_api do
      identity { create :identity, :get_response_api, site: site }
    end

    trait :icontact do
      identity { create :identity, :icontact, site: site }
      data { Hash['embed_code' => build(:embed_code, provider: 'icontact')] }
    end

    trait :infusionsoft do
      identity { create :identity, :infusionsoft, site: site }
    end

    trait :mad_mimi_api do
      identity { create :identity, :mad_mimi_api, site: site }
    end

    trait :mad_mimi_form do
      identity { create :identity, :mad_mimi_form, site: site }
      data { Hash['embed_code' => build(:embed_code, provider: 'mad_mimi_iframe')] }
    end

    trait :mailchimp do
      identity { create :identity, :mailchimp, site: site }
      data { Hash['remote_id' => 1, 'remote_name' => 'test'] }
    end

    trait :maropost do
      identity { create :identity, :maropost, site: site }
    end

    trait :my_emma do
      identity { create :identity, :my_emma, site: site }
      data { Hash['embed_code' => build(:embed_code, provider: 'my_emma_iframe')] }
    end

    trait :verticalresponse do
      identity { create :identity, :verticalresponse, site: site }
    end

    trait :vertical_response do
      identity { create :identity, :vertical_response, site: site }
      data { Hash['embed_code' => build(:embed_code, provider: 'vertical_response')] }
    end

    trait :webhooks do
      identity { create :identity, :webhooks, site: site }
    end

    trait :embed_code_invalid do
      identity { create :identity, :mad_mimi_form, site: site }
      data { Hash['embed_code' => '<html><body><iframe><form>Here I am</form></iframe></body></html>'] }
    end

    trait :embed_code_form do
      identity { create :identity, :mad_mimi_form, site: site }
      data { Hash['embed_code' => '<html><body><form action="https://madmimi.com/signups/iframe_subscribe/103242" id="mad_mimi_signup_form"><input name="signup[name]"/><input name="signup[email]"/></form></body></html>'] }
    end

    trait :embed_iframe do
      identity { create :identity, :mad_mimi_form, site: site }
      data { Hash['embed_code' => build(:embed_code, provider: 'mad_mimi_iframe')] }
    end
  end
end
