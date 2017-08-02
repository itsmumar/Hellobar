describe ContactListsHelper, type: :helper do
  describe '#options_for_provider_select' do
    def options(other)
      {
        requires_app_url: nil,
        requires_embed_code: nil,
        requires_account_id: nil,
        requires_api_key: nil,
        requires_username: nil,
        requires_webhook_url: nil,
        oauth: nil
      }.merge(other)
    end

    it 'returns array of providers with options' do
      expected = [
        ['In Hello Bar only', 0],
        ['AWeber', :aweber, options(oauth: true)],
        ['Active Campaign', :active_campaign, options(requires_app_url: true, requires_api_key: true)],
        ['Campaign Monitor', :createsend, options(oauth: true)],
        ['Constant Contact', :constantcontact, options(oauth: true)],
        ['ConvertKit', :convert_kit, options(requires_api_key: true)],
        ['Drip', :drip, options(oauth: true)],
        ['GetResponse', :get_response_api, options(requires_api_key: true)],
        ['iContact', :icontact, options(requires_embed_code: true)],
        ['Infusionsoft', :infusionsoft, options(requires_app_url: true, requires_api_key: true)],
        ['Iterable', :iterable, options(requires_api_key: true)],
        ['MadMimi', :mad_mimi_api, options(requires_api_key: true, requires_username: true)],
        ['MailChimp', :mailchimp, options(oauth: true)],
        ['Maropost', :maropost, options(requires_account_id: true, requires_api_key: true)],
        ['MyEmma', :my_emma, options(requires_embed_code: true)],
        ['Vertical Response', :verticalresponse, options(oauth: true)],
        ['Webhooks', :webhooks, options(requires_webhook_url: true)]
      ]
      expect(helper.options_for_provider_select).to match_array expected
    end
  end

  describe '#contact_list_sync_details' do
    let(:details) { helper.contact_list_sync_details(contact_list) }

    context 'when remote_name present' do
      let(:contact_list) { create(:contact_list, :aweber, data: { 'remote_name' => 'Remote List Name' }) }

      it 'includes remote list name' do
        expect(details).to include 'Remote List Name'
      end
    end

    context 'when identity present' do
      let(:contact_list) { create(:contact_list, :aweber) }

      it 'includes provider name' do
        expect(details).to include 'AWeber'
      end
    end

    context 'when identity is blank' do
      let(:contact_list) { create(:contact_list) }

      it 'return Storing contacts in Hello Bar' do
        expect(details).to eql '<small>Storing contacts in</small><span>Hello Bar</span>'
      end
    end
  end
end
