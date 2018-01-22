describe 'api/whitelabels requests' do
  let(:site) { create :site }
  let(:user) { create :user, site: site }
  let(:headers) { api_headers_for_site_user site, user }
  let(:params) { Hash[format: :json] }

  describe 'POST #create' do
    let(:domain) { 'hellobar.com' }
    let(:subdomain) { "email.#{ domain }" }
    let(:whitelabel_params) do
      {
        domain: domain,
        subdomain: subdomain,
        site_id: site.id
      }
    end

    context 'when created successfully' do
      it 'returns whitelabel with :created http status' do
        post api_site_whitelabel_path(site),
          params.merge(whitelabel: whitelabel_params),
          headers

        expect(response).to be_successful
        expect(response.code.to_i).to eql 201
        expect(json[:domain]).to eql domain
        expect(json[:subdomain]).to eql subdomain
      end
    end

    context 'when there is an error' do
      it 'returns error code and serialized errors' do
        post api_site_whitelabel_path(site),
          params.merge(whitelabel: whitelabel_params.except(:subdomain)),
          headers

        expect(response).not_to be_successful
        expect(response.code.to_i).to eql 422
        expect(json[:errors][:subdomain]).to be_present
      end
    end
  end

  describe 'GET #show' do
    context 'when whitelabel exists' do
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

    context 'when there is no whitelabel' do
      it 'returns :success with a null response' do
        get api_site_whitelabel_path(site), params, headers

        expect(response).to be_successful
        expect(response.body).to eql 'null'
      end
    end

    context 'when site is not found' do
      it 'returns :not_found response' do
        get api_site_whitelabel_path(site.id + 1), params, headers

        expect(response).not_to be_successful
        expect(json[:errors]).to be_present
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:whitelabel) { create :whitelabel, site: site }

    it 'destroys the whitelabel' do
      delete api_site_whitelabel_path(site.id), params, headers

      expect(response).to be_successful

      expect { Whitelabel.find(whitelabel.id) }
        .to raise_exception ActiveRecord::RecordNotFound
    end
  end
end
