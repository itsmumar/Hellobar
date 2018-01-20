describe 'api/whitelabels requests' do
  let(:site) { create :site }
  let(:user) { create :user, site: site }
  let(:headers) { api_headers_for_site_user site, user }
  let(:params) { Hash[format: :json] }

  describe 'GET #show' do
    let!(:whitelabel) { create :whitelabel, site: site }

    it 'returns whitelabel for a site in the JSON format' do
      get api_site_whitelabel_path(site), params, headers

      expect(response).to be_successful

      expect(json[:id]).to eql whitelabel.id
      expect(json[:domain]).to eql whitelabel.domain
      expect(json[:subdomain]).to eql whitelabel.subdomain
    end

    include_examples 'JWT authentication' do
      def request(headers)
        get api_site_whitelabel_path(site), params, headers
      end
    end
  end
end
