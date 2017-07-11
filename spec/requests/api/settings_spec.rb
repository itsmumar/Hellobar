describe 'api/settings requests' do
  describe 'GET #index' do
    context 'when unauthenticated' do
      it 'responds with :unauthorized' do
        get api_settings_path, format: :json

        expect(response).to be_unauthorized
      end
    end

    context 'when authenticated' do
      let(:user) { create :user }
      let(:site) { create :site, user: user }

      before do
        login_as user, scope: :user, run_callbacks: false
      end

      it 'responds with success' do
        get api_settings_path(site_id: site.id), format: :json
        expect(response).to be_successful
        expect(json).not_to be_blank
      end
    end
  end
end
