describe 'api/sequences' do
  let(:site) { create(:site) }
  let(:user) { create(:user, site: site) }
  let(:contact_list) { create(:contact_list, site: site) }

  let(:headers) { api_headers_for_user(user) }

  describe 'GET #index' do
    let!(:sequences) { create_list(:sequence, 5, contact_list: contact_list) }
    let!(:other_sequences) { create_list(:sequence, 3) }

    let(:path) { api_site_sequences_path(site.id) }

    include_examples 'JWT authentication' do
      def request(headers)
        get(path, { format: :json }, headers)
      end
    end

    before do
      get(path, { format: :json }, headers)
    end

    it 'returns sequences for the site' do
      expect(response).to be_successful

      expect(json[:sequences].size).to eq(sequences.size)

      sequences.each do |sequence|
        expect(json[:sequences]).to include(sequence.attributes.symbolize_keys.slice(:id, :name, :contact_list_id))
      end
    end
  end

  describe 'GET #show' do
    let!(:sequence) { create(:sequence, contact_list: contact_list) }

    let(:path) { api_site_sequence_path(site.id, sequence) }

    include_examples 'JWT authentication' do
      def request(headers)
        get(path, { format: :json }, headers)
      end
    end

    it 'returns the sequence' do
      get(path, { format: :json }, headers)

      expect(response).to be_successful
      expect(json[:id]).to eq(sequence.id)
      expect(json[:name]).to eq(sequence.name)
      expect(json[:contact_list_id]).to eq(sequence.contact_list_id)
    end
  end

  describe 'POST #create' do
    let(:path) { api_site_sequences_path(site.id) }

    let(:sequence_params) do
      attributes_for(:sequence, contact_list_id: contact_list.id)
    end

    let(:params) do
      {
        sequence: sequence_params,
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

    it 'creates a new sequence' do
      expect { post(path, params, headers) }.to change { Sequence.count }.by(1)
    end

    it 'returns newly created sequence' do
      post(path, params, headers)

      expect(response).to be_successful
      expect(json).to include(sequence_params)
    end

    context 'with invalid params' do
      let(:sequence_params) do
        { name: 'Sequence #1' }
      end

      it 'returns errors JSON' do
        post(path, params, headers)

        expect(response).not_to be_successful
        expect(json[:errors]).to be_present
      end
    end
  end

  describe 'PUT #update' do
    let!(:sequence) { create(:sequence, contact_list: contact_list) }

    let(:path) { api_site_sequence_path(site.id, sequence) }

    let(:sequence_params) do
      { name: 'New Name' }
    end

    let(:params) do
      {
        sequence: sequence_params,
        format: :json
      }
    end

    include_examples 'JWT authentication' do
      def request(headers)
        put(path, params, headers)
      end
    end

    it 'reply with success' do
      put(path, params, headers)

      expect(response).to be_successful
    end

    it 'updates sequence' do
      put(path, params, headers)

      sequence.reload

      expect(sequence.name).to eq(sequence_params[:name])
    end

    it 'returns updated sequence' do
      put(path, params, headers)

      expect(json).to include(sequence_params)
    end

    context 'with invalid params' do
      let(:sequence_params) do
        { name: '' }
      end

      it 'returns errors JSON' do
        put(path, params, headers)

        expect(response).not_to be_successful
        expect(json[:errors]).to be_present
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:sequence) { create(:sequence, contact_list: contact_list) }

    let(:path) { api_site_sequence_path(site.id, sequence) }

    let(:params) { { format: :json } }

    include_examples 'JWT authentication' do
      def request(headers)
        delete(path, params, headers)
      end
    end

    it 'reply with success' do
      delete(path, params, headers)

      expect(response).to be_successful
      expect(json).to include(message: 'Sequence has been successfully deleted.')
    end

    it 'marks sequence as deleted' do
      delete(path, params, headers)

      sequence.reload

      expect(sequence).to be_deleted
    end
  end
end
