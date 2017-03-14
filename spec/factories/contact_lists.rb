FactoryGirl.define do
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

    trait :embed_code do
      identity { create :identity, :mad_mimi, site: site }
      data { Hash['embed_code' => '<html><body><iframe><form>Here I am</form></iframe></body></html>'] }
    end

    trait :embed_iframe do
      identity { create :identity, :mad_mimi, site: site }
      data { Hash['embed_code' => '<iframe src="https://madmimi.com/signups/103242/iframe" scrolling="no" frameborder="0" height="405" width="400"></iframe>'] }
    end
  end
end
