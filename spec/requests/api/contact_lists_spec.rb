describe 'api/contact_lists' do
  let(:site) { create(:site) }
  let(:user) { create(:user, site: site) }

  let(:headers) { api_headers_for_user(user) }

  describe 'POST #create' do
    let(:path) { api_site_contact_lists_path(site.id) }

    let(:contact_list_params) do
      attributes_for(:contact_list, data: {})
    end

    let(:params) do
      {
        contact_list: contact_list_params,
        format: :json
      }
    end

    include_examples 'JWT authentication' do
      def request(headers)
        post(path, params, headers)
      end
    end

    it 'reply with success' do
      post(path, params, headers)

      expect(response).to be_successful
    end

    it 'creates a new contact list' do
      expect { post(path, params, headers) }.to change { ContactList.count }.by(1)
    end

    it 'returns newly created contact list' do
      post(path, params, headers)

      expect(response).to be_successful
      expect(json).to include(contact_list_params)
    end

    context 'with invalid params' do
      let(:contact_list_params) do
        { name: '' }
      end

      it 'returns errors JSON' do
        post(path, params, headers)

        expect(response).not_to be_successful
        expect(json[:errors]).to be_present
      end
    end
  end
end
