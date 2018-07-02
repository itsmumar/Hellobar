describe DestroyWhitelabel do
  let(:site) { create :site }
  let(:api_url) { 'https://api.sendgrid.com/v3' }
  let(:domain_identifier) { 199 }

  describe '#call' do
    it 'destroys database record when there is no identifier' do
      site = create :site
      whitelabel = create :whitelabel, site: site, domain_identifier: nil

      DestroyWhitelabel.new(site: site).call

      expect(whitelabel).to be_destroyed
    end

    it 'sends delete request to SendGrid and deletes from database' do
      stub_request(:delete, "#{ api_url }/whitelabel/domains/#{ domain_identifier }")
        .to_return status: 204

      site = create :site
      whitelabel = create :whitelabel, site: site, domain_identifier: domain_identifier

      DestroyWhitelabel.new(site: site).call

      expect(whitelabel).to be_destroyed
    end

    it 'does nothing when there is no whitelabel' do
      expect(DestroyWhitelabel.new(site: site).call).to be_nil
    end
  end
end
