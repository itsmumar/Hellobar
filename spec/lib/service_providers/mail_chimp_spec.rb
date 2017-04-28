describe ServiceProviders::MailChimp, :vcr do
  let(:credentials) { { 'token' => 'b5b4381641823db514e26a4709b1c202-us14' } }
  let(:list_id) { '96341e9476' }
  let(:extra) { { 'metadata' => { 'api_endpoint' => 'https://us14.api.mailchimp.com' } } }
  let(:existing_subscriber) { 'anton.sozontov@crossover.com' }
  let(:site) { create :site }
  let(:identity) { Identity.new(provider: 'mailchimp', extra: extra, credentials: credentials, site: site) }
  let(:service_provider) { identity.service_provider }
  let(:client) { service_provider.instance_variable_get(:@client) }

  describe 'subscribe' do
    context 'when Invalid Resource error' do
      it 'catches it' do
        expect {
          service_provider.subscribe(list_id, 'abc')
        }.not_to raise_error
      end
    end

    context 'when Member Exists error' do
      it 'catches it' do
        expect {
          service_provider.subscribe(list_id, existing_subscriber)
        }.not_to raise_error
      end
    end
  end

  describe 'lists' do
    it 'returns available lists' do
      expect(service_provider.lists.map { |list| list['id'] }).to eq [list_id]
    end
  end

  describe 'email_exists?' do
    context 'when exists' do
      it 'returns true' do
        expect(service_provider.email_exists?(list_id, existing_subscriber)).to be_truthy
      end
    end

    context 'when does not exist' do
      it 'returns true' do
        expect(service_provider.email_exists?(list_id, 'doesnotexist@email.com')).to be_falsey
      end
    end
  end
end
