describe 'api/contact_lists requests' do
  let(:site) { create :site }
  let(:user) { create :user, site: site }
  let(:headers) { api_headers_for_user(user) }

  before { allow(FetchContactListTotals).to receive_service_call }

  describe 'GET #index' do
    let(:params) { { format: :json } }
    let(:path) { api_site_contact_lists_path(site.id) }

    it 'returns campaigns for the site in the JSON format' do
      contact_list = create :contact_list, site: site

      get(path, params, headers)

      expect(response).to be_successful

      contact_lists = json[:contact_lists]

      expect(contact_lists.first[:id]).to eq contact_list.id
      expect(contact_lists.first[:name]).to eq contact_list.name
    end

    include_examples 'JWT authentication' do
      def request(headers)
        get(path, params, headers)
      end
    end
  end
end
