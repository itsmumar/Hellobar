describe 'contact lists API' do
  let(:user) { create(:user) }
  let(:token) { create_oauth_token(user, scopes: 'contact_lists') }

  let(:params) { {} }
  let(:headers) { { 'Authorization' => "Bearer #{ token }" } }

  let(:site) { create(:site, user: user) }

  describe 'list' do
    let!(:contact_lists) { create_list(:contact_list, 3, site: site) }

    # not matching contact lists
    let!(:mailchimp_list) { create(:contact_list, :mailchimp, site: site) }
    let!(:other_site_list) { create(:contact_list) }

    let(:request) { get(api_external_site_contact_lists_path(site_id: site.id, format: :json), params, headers) }

    it 'returns list of contact lists that does not use any integration' do
      request

      expect(response).to be_successful
      expect(json).to be_an(Array)
      expect(json).to match(contact_lists.map { |site| { id: site.id, name: site.name } })
    end

    include_examples 'invalid oauth token'
  end

  describe 'subscribe' do
    let(:contact_list) { create(:contact_list, site: site) }

    let(:params) do
      {
        provider: :zapier,
        webhook_url: 'https://zapier.com/123/qwe',
        webhook_method: 'POST'
      }
    end

    let(:path) { subscribe_api_external_site_contact_list_path(site_id: site.id, id: contact_list.id, format: :json) }

    let(:request) do
      post(path, params, headers)
    end

    it 'attaches integration to given contact list' do
      request

      updated_list = contact_list.reload

      expect(updated_list.provider_name).to eq('Zapier')
      expect(updated_list.data[:webhook_url]).to eq(params[:webhook_url])
      expect(updated_list.data[:webhook_method]).to eq(params[:webhook_method])
    end

    include_examples 'invalid oauth token'

    context 'when contact list is already used' do
      let(:contact_list) { create(:contact_list, :zapier, site: site) }

      it 'returns error' do
        request

        expect(response).not_to be_successful
        expect(json).to include(error: 'Contact list is already used by other integration')
      end
    end
  end

  describe 'unsubscribe' do
    let(:contact_list) { create(:contact_list, :zapier, site: site) }

    let(:path) { unsubscribe_api_external_site_contact_list_path(site_id: site.id, id: contact_list.id, format: :json) }

    let(:request) do
      post(path, params, headers)
    end

    it 'detaches integration from given contact list but keeps webhook settings' do
      request

      updated_list = contact_list.reload

      expect(updated_list.provider_name).to eq('Hello Bar')
      expect(updated_list.data[:webhook_url]).to be_present
      expect(updated_list.data[:webhook_method]).to be_present
    end

    include_examples 'invalid oauth token'
  end
end
