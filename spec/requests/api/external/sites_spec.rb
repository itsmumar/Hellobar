describe 'sites API' do
  let(:user) { create(:user) }
  let(:token) { create_oauth_token(user, scopes: 'sites') }

  let(:params) { {} }
  let(:headers) { { 'Authorization' => "Bearer #{ token }" } }

  let!(:sites) { create_list(:site, 3, user: user) }

  # not matching sites
  let!(:other_site) { create(:site) }

  describe 'list' do
    let(:request) { get(api_external_sites_path(format: :json), params, headers) }

    it 'returns list of user\'s sites' do
      request

      expect(response).to be_successful
      expect(json).to be_an(Array)
      expect(json).to match(sites.map { |site| { id: site.id, host: site.host } })
    end

    include_examples 'invalid oauth token'
  end
end
