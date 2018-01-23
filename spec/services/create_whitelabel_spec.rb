describe CreateWhitelabel do
  describe '#call' do
    let(:site) { create :site }

    let(:domain) { 'hellobar.com' }
    let(:subdomain) { "email.#{ domain }" }
    let(:params) do
      {
        domain: domain,
        subdomain: subdomain
      }
    end

    let(:api_url) { 'https://api.sendgrid.com/v3' }

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

    let(:erroneous_api_response) do
      {
        errors: [
          {
            message: 'A domain whitelabel already exists for this URL.'
          }
        ]
      }
    end

    it 'does not create a whitelabel and raises if already exists' do
      create :whitelabel, site: site

      expect {
        CreateWhitelabel.new(site: site, params: params).call
      }.to raise_exception ActiveRecord::RecordInvalid, /Validation failed/
    end

    it 'does not create a whitelabel and raises if model validation fails' do
      expect {
        CreateWhitelabel.new(site: site, params: params.except(:subdomain)).call
      }.to raise_exception ActiveRecord::RecordInvalid, /Validation failed/
    end

    it 'does not create a whitelabel and raises if SendGrid returns an error' do
      stub_request(:post, "#{ api_url }/whitelabel/domains")
        .to_return status: 400, body: erroneous_api_response.to_json

      expect {
        CreateWhitelabel.new(site: site, params: params).call
      }.to raise_exception ActiveRecord::RecordInvalid, /Validation failed/
    end

    it 'saves whitelabel and creates it at SendGrid' do
      stub_request(:post, "#{ api_url }/whitelabel/domains")
        .with(body: api_params)
        .to_return status: 201, body: api_response.to_json

      whitelabel = CreateWhitelabel.new(site: site, params: params).call

      expect(whitelabel).to be_persisted
      expect(whitelabel.domain).to eql domain
      expect(whitelabel.domain_identifier).to eql domain_identifier
      expect(whitelabel.subdomain).to eql subdomain
      expect(whitelabel.dns_records).to eql [dns_record]
    end
  end
end
