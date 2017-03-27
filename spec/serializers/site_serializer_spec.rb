require 'spec_helper'

describe SiteSerializer do
  let(:site) { build_stubbed :site }
  let(:user) { build_stubbed :user }
  let(:serialized_site) { SiteSerializer.new(site, scope: user) }
  let(:serializable_hash) { serialized_site.serializable_hash }

  it 'serializes capabilities' do
    expect(serializable_hash[:capabilities]).to be_a Hash

    %i(remove_branding closable custom_targeted_bars at_site_element_limit
       custom_thank_you_text after_submit_redirect custom_html content_upgrades
       autofills geolocation_injection external_tracking).each do |key|
      expect(serializable_hash[:capabilities]).to have_key key
    end
  end

  describe '#to_json' do
    context 'when raises Google::Apis::AuthorizationError' do
      before do
        allow(user).to receive(:authentications).and_return([Authentication.new(provider: 'google_oauth2')])
        allow_any_instance_of(GoogleAnalytics)
          .to receive(:latest_pageviews).and_raise(Google::Apis::AuthorizationError, 'Unauthorized')
      end

      it 're-raises error' do
        expect { serialized_site.to_json }.to raise_error Google::Apis::AuthorizationError
      end

      context 'when user is_impersonated' do
        let(:user) { build_stubbed :user, is_impersonated: true }

        it 'returns nil' do
          expect(serialized_site.to_json).to include '"monthly_pageviews":null'
        end
      end
    end
  end
end
