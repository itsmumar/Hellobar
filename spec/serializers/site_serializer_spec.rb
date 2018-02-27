describe SiteSerializer do
  let(:site) { create :site }
  let(:user) { build_stubbed :user }
  let(:serialized_site) { SiteSerializer.new(site, scope: user) }
  let(:serializable_hash) { serialized_site.serializable_hash }

  before { allow(site).to receive(:script_installed?).and_return true }

  it 'serializes capabilities' do
    expected_capabilities = {
      remove_branding: site.capabilities.remove_branding?,
      closable: site.capabilities.closable?,
      custom_targeted_bars: site.capabilities.custom_targeted_bars?,
      at_site_element_limit: site.capabilities.at_site_element_limit?,
      custom_thank_you_text: site.capabilities.custom_thank_you_text?,
      after_submit_redirect: site.capabilities.after_submit_redirect?,
      content_upgrades: site.capabilities.content_upgrades?,
      autofills: site.capabilities.autofills?,
      geolocation_injection: site.capabilities.geolocation_injection?,
      external_tracking: site.capabilities.external_tracking?,
      alert_bars: site.capabilities.alert_bars?,
      opacity: site.capabilities.opacity?,
      precise_geolocation_targeting: site.capabilities.precise_geolocation_targeting?
    }
    expect(serializable_hash[:capabilities]).to match expected_capabilities
  end

  context 'with contact_lists' do
    let!(:contact_list) { create :contact_list, site: site }

    it 'serializes contact_lists' do
      expect(serializable_hash).to include contact_lists: [
        {
          id: contact_list.id,
          name: contact_list.name,
          provider_name: contact_list.provider_name
        }
      ]
    end

    context 'when totals are passed to the context' do
      let(:subscribers_count) { 5 }
      let(:context) { { list_totals: { contact_list.id => subscribers_count } } }
      let(:serialized_site) { SiteSerializer.new(site, scope: user, context: context) }

      it 'returns subscribers_count attribute' do
        expect(serializable_hash).to include(contact_lists: [
          hash_including(subscribers_count: subscribers_count)
        ])
      end
    end
  end

  context 'with current_subscription' do
    let!(:subscription) { create :subscription, site: site }

    before { allow(SubscriptionSerializer).to receive(:new).and_return :subscription }

    it 'serializes subscription' do
      expect(serializable_hash).to include current_subscription: :subscription
    end
  end
end
