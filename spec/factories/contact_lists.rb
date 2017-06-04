FactoryGirl.define do
  factory :embed_code, class: String do
    skip_create
    provider 'my_emma'

    initialize_with do
      Rails.root.join('spec', 'support', 'embed_code', "#{ provider }.html").read
    end
  end

  factory :contact_list do
    site
    name 'My List'

    trait :with_tags do
      data('tags' => ['id1', 'id2'])
    end

    trait :mailchimp do
      identity { create :identity, :mailchimp, site: site }
      data { Hash['remote_id' => 1, 'remote_name' => 'test'] }
    end

    trait :drip do
      identity { create :identity, :drip, site: site }
      data { Hash['remote_id' => 1] }
    end

    trait :maropost do
      data { Hash['remote_id' => 1] }
    end

    trait :vertical_response do
      identity { create :identity, :vertical_response, site: site }
      data { Hash['embed_code' => build(:embed_code, provider: 'vertical_response')] }
    end

    trait :verticalresponse do
      data { Hash['remote_id' => 1] }
    end

    trait :my_emma do
      identity { create :identity, :my_emma, site: site }
      data { Hash['embed_code' => build(:embed_code, provider: 'my_emma_iframe')] }
    end

    trait :embed_code do
      identity { create :identity, :mad_mimi, site: site }
      data { Hash['embed_code' => '<html><body><iframe><form>Here I am</form></iframe></body></html>'] }
    end

    trait :embed_code_form do
      identity { create :identity, :mad_mimi, site: site }
      data { Hash['embed_code' => '<html><body><form id="mad_mimi_signup_form"><input name="signup[name]"/><input name="signup[email]"/></form></body></html>'] }
    end

    trait :embed_iframe do
      identity { create :identity, :mad_mimi, site: site }
      data { Hash['embed_code' => build(:embed_code, provider: 'mad_mimi_iframe')] }
    end

    trait :embed_icontact do
      identity { create :identity, :icontact, site: site }
      data { Hash['embed_code' => build(:embed_code, provider: 'icontact')] }
    end

    trait :embed_mad_mimi do
      identity { create :identity, :mad_mimi, site: site }
      data { Hash['embed_code' => build(:embed_code, provider: 'mad_mimi_iframe')] }
    end
  end
end
