describe 'api/internal/sites requests' do
  describe 'POST #update_install_type' do
    context 'when unauthenticated' do
      it 'responds with :unauthorized' do
        post update_install_type_api_internal_site_path(1), format: :json

        expect(response).to be_unauthorized
      end
    end

    context 'when authenticated' do
      let!(:site) { create :site }
      let(:token) { Settings.api_token }
      let(:install_type) { 'wordpress' }
      let(:params) { Hash[site: { install_type: install_type }, format: :json] }
      let(:headers) { Hash['Authorization' => "Token token=#{ token }"] }

      it 'updates install_type param' do
        post update_install_type_api_internal_site_path(site), params, headers

        expect(response).to be_successful
        expect(site.reload.install_type).to eq install_type
      end
    end
  end

  describe 'POST #update_static_script_installation' do
    context 'when unauthenticated' do
      it 'responds with :unauthorized' do
        post update_static_script_installation_api_internal_site_path(1), format: :json

        expect(response).to be_unauthorized
      end
    end

    context 'when authenticated' do
      let!(:site) { create :site }
      let(:token) { Settings.api_token }
      let(:params) { Hash[site: { installed: true }, format: :json] }
      let(:headers) { Hash['Authorization' => "Token token=#{ token }"] }

      it 'sets site script as installed', :freeze do
        post update_static_script_installation_api_internal_site_path(site), params, headers

        expect(response).to be_successful
        expect(site.reload.script_installed_at).to eq Time.current
      end
    end
  end
end
