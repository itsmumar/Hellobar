describe 'api/sites/:id/search requests' do
  let(:site) { create :site }
  let(:user) { create :user, site: site }
  let!(:campaign) { create :campaign, :draft, site: site }
  let(:headers) { api_headers_for_user(user) }
  let(:params) { Hash[format: :json] }
  let(:search_params) do
    { query: 'Hello',
      flag: 'drafts' }
  end

  context 'search for an email' do
    it 'responds with success' do
      post search_api_site_emails_path(site),
        params.merge(email: search_params),
        headers
      expect(response).to be_successful
      expect(response.code.to_i).to eql 200
      expect(json.first[:body]).to eql 'Test Campaign'
      expect(json.count).to eql 1
    end
  end

  context 'create a new email' do
    let(:params) { Hash[format: :json] }
    let(:email_params) do
      {
        site_id: site.id,
        subject: 'Test Subject',
        body: 'Test body over here',
        from_name: 'Homer Simpson',
        from_email: 'homer@springfieldpowerplant.com'
      }
    end

    it 'post email params' do
      post api_site_emails_path(site),
        params.merge(email: email_params),
        headers

      expect(response).to be_successful
      expect(json[:subject]).to eql 'Test Subject'
    end
  end
end
