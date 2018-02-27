describe Api::UsersController do
  describe 'GET #show' do
    let(:user) { create :user }
    let(:params) { { format: :json } }
    let(:headers) { api_headers_for_user(user) }

    before do
      allow(FetchContactListTotals).to receive_service_call
    end

    include_examples 'JWT authentication' do
      def request(headers)
        get current_api_users_path, params, headers
      end
    end

    it 'responds with user JSON' do
      get current_api_users_path, params, headers

      expect(response).to be_successful
      expect(json).not_to be_blank
    end
  end
end
