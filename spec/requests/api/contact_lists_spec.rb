describe 'api/contact_lists requests' do
  let(:site) { create :site }
  let(:user) { create :user, site: site }
  let(:headers) { api_headers_for_site_user site, user }

  before { allow(FetchContactListTotals).to receive_service_call }

  describe 'GET #index' do
    let(:params) { Hash[format: :json] }

    it 'returns campaigns for the site in the JSON format' do
      contact_list = create :contact_list, site: site

      get api_contact_lists_path, params, headers

      expect(response).to be_successful

      contact_lists = json[:contact_lists]

      expect(contact_lists.first[:id]).to eq contact_list.id
      expect(contact_lists.first[:name]).to eq contact_list.name
    end

    include_examples 'JWT authentication' do
      def request(headers)
        get api_campaigns_path, params, headers
      end
    end
  end
end
