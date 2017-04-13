describe ServiceProviders::MailChimp, :vcr do
  let(:credentials) { { 'token' => 'b5b4381641823db514e26a4709b1c202-us14' } }
  let(:extra) { { 'metadata' => { 'api_endpoint' => 'https://us14.api.mailchimp.com' } } }
  let(:site) { create :site }
  let(:identity) { Identity.new(provider: 'mailchimp', extra: extra, credentials: credentials, site: site) }
  let(:service_provider) { identity.service_provider }
  let(:client) { service_provider.instance_variable_get(:@client) }

  describe 'subscribe' do
    context 'when Invalid Resource error' do
      it 'catches it' do
        expect {
          service_provider.subscribe('0503e0a88a', 'abc')
        }.not_to raise_error
      end
    end

    context 'when Member Exists error' do
      it 'catches it' do
        service_provider.subscribe('0503e0a88a', 'anton.sozontov@crossover.com')
        expect {
          service_provider.subscribe('0503e0a88a', 'anton.sozontov@crossover.com')
        }.not_to raise_error
      end
    end
  end

  describe 'lists' do
    it 'returns available lists' do
      expect(service_provider.lists.map { |list| list['id'] }).to match_array %w(0503e0a88a 68e477ba92 96341e9476)
    end
  end

  describe 'email_exists?' do
    context 'when exists' do
      it 'returns true' do
        expect(service_provider.email_exists?('0503e0a88a', 'anton.sozontov@crossover.com')).to be_truthy
      end
    end

    context 'when does not exist' do
      it 'returns true' do
        expect(service_provider.email_exists?('0503e0a88a', 'doesnotexist@email.com')).to be_falsey
      end
    end
  end
end
