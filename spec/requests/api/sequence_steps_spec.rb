describe 'api/sequence_steps' do
  let(:site) { create(:site) }
  let(:user) { create(:user, site: site) }
  let(:contact_list) { create(:contact_list, site: site) }
  let(:sequence) { create(:sequence, contact_list: contact_list) }

  let(:headers) { api_headers_for_user(user) }

  describe 'GET #index' do
    let!(:steps) { create_list(:sequence_step, 5, sequence: sequence) }
    let!(:other_steps) { create_list(:sequence_step, 3) }

    let(:path) { api_site_sequence_steps_path(site.id, sequence.id) }

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

      expect(json[:sequence_steps].size).to eq(steps.size)

      steps.each do |step|
        expected_attributes = step.attributes.symbolize_keys.slice(:id, :delay, :executable_type, :executable_id)
        expect(json[:sequence_steps]).to include(expected_attributes)
      end
    end
  end

  describe 'GET #show' do
    let!(:step) { create(:sequence_step, sequence: sequence) }

    let(:path) { api_site_sequence_step_path(site.id, sequence.id, step) }

    include_examples 'JWT authentication' do
      def request(headers)
        get(path, { format: :json }, headers)
      end
    end

    it 'returns the sequence' do
      get(path, { format: :json }, headers)

      expect(response).to be_successful
      expect(json[:id]).to eq(step.id)
      expect(json[:delay]).to eq(step.delay)
      expect(json[:executable_type]).to eq(step.executable_type)
      expect(json[:executable_id]).to eq(step.executable_id)
    end
  end

  describe 'POST #create' do
    let(:path) { api_site_sequence_steps_path(site.id, sequence.id) }
    let(:email) { create(:email) }

    let(:step_params) do
      attributes_for(:sequence_step, executable_type: email.class.name, executable_id: email.id)
    end

    let(:params) do
      {
        sequence_step: step_params,
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
      expect { post(path, params, headers) }.to change { SequenceStep.count }.by(1)
    end

    it 'returns newly created sequence' do
      post(path, params, headers)

      expect(response).to be_successful
      expect(json).to include(step_params)
    end

    context 'with invalid params' do
      let(:step_params) do
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
    let!(:step) { create(:sequence_step, sequence: sequence) }

    let(:path) { api_site_sequence_step_path(site.id, sequence.id, step) }

    let(:step_params) do
      { delay: 999 }
    end

    let(:params) do
      {
        sequence_step: step_params,
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

      step.reload

      expect(step.delay).to eq(step_params[:delay])
    end

    it 'returns updated sequence' do
      put(path, params, headers)

      expect(json).to include(step_params)
    end

    context 'with invalid params' do
      let(:step_params) do
        { delay: '' }
      end

      it 'returns errors JSON' do
        put(path, params, headers)

        expect(response).not_to be_successful
        expect(json[:errors]).to be_present
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:step) { create(:sequence_step, sequence: sequence) }

    let(:path) { api_site_sequence_step_path(site.id, sequence.id, step) }

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

    it 'marks sequence step as deleted' do
      delete(path, params, headers)

      step.reload

      expect(step).to be_deleted
    end
  end
end
