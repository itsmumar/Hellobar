describe ServiceProviders::ActiveCampaign do
  let(:identity) do
    Identity.new(
      provider: 'active_campaign',
      api_key: 'valid-active-campaign-key',
      extra: { 'app_url' => 'hellobar.api-us1.com' }
    )
  end
  let(:service_provider) { identity.service_provider }
  let(:cassette_base) { 'service_providers/active_campaign' }
  let(:client) { service_provider.instance_variable_get(:@client) }

  describe '#lists', vcr: 'service_providers/active_campaign/lists' do
    it 'should call `list_list`' do
      expect(client).to receive(:list_list).and_return('result_code' => 1)
      service_provider.lists
    end

    it 'should return lists' do
      expect(service_provider.lists.count).to eq(2)
    end
  end

  describe '#subscribe' do
    context 'NOT having `list_id`' do
      it 'should call contact_sync', vcr: 'service_providers/active_campaign/contact_sync' do
        email = 'test@test.com'
        expect(client).to receive(:contact_sync).with(email: email)

        service_provider.subscribe(nil, email)
      end

      it 'should new contact with email', vcr: 'service_providers/active_campaign/contact_sync' do
        response = service_provider.subscribe(nil, 'test@test.com')
        expect(response['result_message']).to eq('Contact added')
      end

      it 'should add email and name', vcr: 'service_providers/active_campaign/contact_sync_with_name' do
        response = service_provider.subscribe(nil, 'test1@test.com', 'Test User')
        expect(response['result_message']).to eq('Contact added')
      end
    end

    context 'having `list_id`' do
      it 'should add user to the list, when `list_id` is present', vcr: 'service_providers/active_campaign/contact_sync_with_list_id' do
        response = service_provider.subscribe(nil, 'test2@test.com', 'Test User')
        expect(response['result_message']).to eq('Contact added')
      end
    end
  end

  describe '#batch_subscribe' do
    it 'should call `contact_sync` 3 times', vcr: 'service_providers/active_campaign/contact_sync_with_name' do
      expect(client).to receive(:contact_sync).exactly(2).times

      subscribers = [{ email: 'raj.kumar+99@crossover.com', name: 'R K' },
                     { email: 'raj.kumar+98@crossover.com', name: 'RK' }]
      service_provider.batch_subscribe(nil, subscribers)
    end
  end
end
