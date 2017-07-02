describe 'api/user_states requests' do
  describe 'GET #show' do
    let(:user) { create :user }

    context 'when unauthenticated' do
      it 'responds with :unauthorized' do
        get api_user_state_path(user.id), format: :json

        expect(response).to be_unauthorized
      end
    end

    context 'when authenticated' do
      let(:admin) { create :admin, api_token: 'token' }

      it 'responds with success' do
        get api_user_state_path(user.id), api_token: admin.api_token, format: :json
        expect(response).to be_successful
        expect(json).not_to be_blank
      end
    end
  end
end
