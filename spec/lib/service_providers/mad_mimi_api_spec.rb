describe ServiceProviders::MadMimiApi do
  describe '.initialize' do
    it 'raises an error if no identity is provided' do
      expect { ServiceProviders::MadMimiApi.new }.to raise_error('Must provide an identity through the arguments')
    end

    it 'raises error if identity is missing api key' do
      identity = Identity.new site_id: 1, provider: 'mad_mimi_api', credentials: { 'username' => 'abc' }
      expect { ServiceProviders::MadMimiApi.new(identity: identity) }.to raise_error('Identity does not have a stored MadMimi API key')
    end

    it 'raises error if identity is missing a username in the credentials' do
      identity = Identity.new site_id: 1, provider: 'mad_mimi_api', api_key: 'abc', credentials: {}
      expect { ServiceProviders::MadMimiApi.new(identity: identity) }.to raise_error('Identity does not have a stored MadMimi email')
    end
  end

  describe 'api calls' do
    let(:identity) { Identity.new site_id: 1, provider: 'mad_mimi_api', api_key: '123', credentials: { 'username' => 'abc' } }
    let(:service_provider) { ServiceProviders::MadMimiApi.new(identity: identity) }

    describe '#lists' do
      it 'returns an array of lists' do
        expect(service_provider.lists).to eq([{
          'id' => '1266012',
          'name' => 'TEST LIST',
          'subscriber_count' => '1',
          'display_name' => ''
        }])
      end
    end

    describe '#subscribe' do
      it 'delegates to MadMimi#add_to_list' do
        email = 'email@example.com'
        name = 'Happy Gilmore'
        list_id = '123'

        expect(service_provider.instance_variable_get(:@client))
          .to receive(:add_to_list).with(email, list_id, name: name)
        service_provider.subscribe(list_id, email, name)
      end
    end

    describe '#batch_subscribe' do
      it 'delegates to MadMimi#add_users' do
        list_id = '123'
        subscribers = [{ email: 'abc@123.com' }, { email: '123@abc.com' }]

        expect(service_provider.instance_variable_get(:@client))
          .to receive(:add_users).with([{ email: 'abc@123.com', name: nil, add_list: list_id }, { email: '123@abc.com', name: nil, add_list: list_id }])
        service_provider.batch_subscribe(list_id, subscribers)
      end
    end

    describe '#valid?' do
      it 'returns true if the api call to lists succeeds' do
        expect(service_provider.valid?).to eq(true)
      end

      it 'returns false if the api call to lists fails' do
        identity = Identity.new site_id: 1, provider: 'mad_mimi_api', api_key: 'invalid_api', credentials: { 'username' => 'invalid user name' }
        service_provider = ServiceProviders::MadMimiApi.new(identity: identity)
        expect(service_provider.valid?).to eq(false)
      end
    end
  end
end
