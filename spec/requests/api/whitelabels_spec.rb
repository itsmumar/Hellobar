describe 'api/whitelabels requests' do
  let(:site) { create :site }
  let(:user) { create :user, site: site }
  let(:headers) { api_headers_for_site_user site, user }
  let(:params) { Hash[format: :json] }
  let(:api_url) { 'https://api.sendgrid.com/v3' }

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
      let(:api_params) do
        {
          domain: domain,
          subdomain: subdomain,
          default: false,
          automatic_security: true,
          custom_spf: false
        }
      end

      let(:domain_identifier) { 199 }
      let(:dns_record) do
        {
          'cname' => 'cname',
          'validated' => false
        }
      end

      let(:api_response) do
        {
          id: domain_identifier,
          dns: [dns_record]
        }
      end

      before do
        stub_request(:post, "#{ api_url }/whitelabel/domains")
          .with(body: api_params)
          .to_return status: 201, body: api_response.to_json
      end

      it 'creates whitelabel at SendGrid and returns :created with whitelabel' do
        post api_site_whitelabel_path(site),
          params.merge(whitelabel: whitelabel_params),
          headers

        expect(response).to be_successful
        expect(response.code.to_i).to eql 201

        expect(json[:domain]).to eql domain
        expect(json[:subdomain]).to eql subdomain
        expect(json[:domain_identifier]).to eql domain_identifier
        expect(json[:dns]).to eql [dns_record]
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
    let(:url) { "#{ api_url }/whitelabel/domains/#{ whitelabel.domain_identifier }" }

    before do
      stub_request(:delete, url)
        .to_return status: 204
    end

    it 'destroys the whitelabel' do
      delete api_site_whitelabel_path(site.id), params, headers

      expect(response).to be_successful

      expect { Whitelabel.find(whitelabel.id) }
        .to raise_exception ActiveRecord::RecordNotFound
    end
  end

  describe 'POST #validate' do
    let!(:whitelabel) { create :whitelabel, site: site }
    let(:url) { "#{ api_url }/whitelabel/domains/#{ whitelabel.domain_identifier }/validate" }

    context 'when validation succeeds' do
      let(:api_response) do
        {
          id: whitelabel.domain_identifier,
          valid: true
        }
      end

      before do
        stub_request(:post, url)
          .to_return status: 200, body: api_response.to_json
      end

      it 'validates the whitelabel' do
        post validate_api_site_whitelabel_path(site.id), params, headers

        expect(response).to be_successful

        expect(Whitelabel.find(whitelabel.id).status).to eql Whitelabel::VALID
      end
    end

    context 'when validation fails' do
      let(:api_response) do
        {
          id: whitelabel.domain_identifier,
          valid: false,
          validation_results: {
            mail_cname: {
              valid: false,
              reason: 'Expected CNAME to match'
            },
            dkim1: {
              valid: false,
              reason: 'Expected CNAME to match'
            },
            dkim2: {
              valid: false,
              reason: 'Expected CNAME to match'
            }
          }
        }
      end

      before do
        stub_request(:post, url)
          .to_return status: 200, body: api_response.to_json
      end

      it 'invalidates the whitelabel' do
        post validate_api_site_whitelabel_path(site.id), params, headers

        expect(response).not_to be_successful

        errors = json['errors']

        expect(errors[:base]).to include 'Validation failed'
        expect(errors[:domain]).to include 'Expected CNAME to match'

        expect(Whitelabel.find(whitelabel.id).status).to eql Whitelabel::INVALID
      end
    end
  end
end
