require 'spec_helper'

describe SiteSerializer do
  let(:site) { build_stubbed :site }
  let(:serialized_site) { SiteSerializer.new(site) }
  let(:serializable_hash) { serialized_site.serializable_hash }

  it 'serializes capabilities' do
    expect(serializable_hash[:capabilities]).to be_a Hash

    %i(remove_branding closable custom_targeted_bars at_site_element_limit
       custom_thank_you_text after_submit_redirect custom_html content_upgrades
       autofills geolocation_injection external_events).each do |key|
      expect(serializable_hash[:capabilities]).to have_key key
    end
  end
end
