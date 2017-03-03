require 'spec_helper'

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

  describe '#lists' do
    it 'should call `list_list`' do
      VCR.use_cassette(cassette_base + '/lists') do
        expect(client).to receive(:list_list).and_return({ 'result_code' => 1 })
        service_provider.lists
      end
    end

    it 'should return lists' do
      VCR.use_cassette(cassette_base + '/lists') do
        expect(service_provider.lists.count).to eq(2)
      end
    end
  end

  describe '#subscribe' do
    context 'NOT having `list_id`' do
      it 'should call contact_sync' do
        email = 'test@test.com'
        expect(client).to receive(:contact_sync).with({ email: email })

        VCR.use_cassette(cassette_base + '/contact_sync') do
          service_provider.subscribe(nil, email)
        end
      end

      it 'should new contact with email' do
        VCR.use_cassette(cassette_base + '/contact_sync') do
          response = service_provider.subscribe(nil, 'test@test.com')
          expect(response['result_message']).to eq('Contact added')
        end
      end

      it 'should add email and name' do
        VCR.use_cassette(cassette_base + '/contact_sync_with_name') do
          response = service_provider.subscribe(nil, 'test1@test.com', 'Test User')
          expect(response['result_message']).to eq('Contact added')
        end
      end
    end

    context 'having `list_id`' do
      it 'should add user to the list, when `list_id` is present' do
        VCR.use_cassette(cassette_base + '/contact_sync_with_list_id') do
          response = service_provider.subscribe(nil, 'test2@test.com', 'Test User')
          expect(response['result_message']).to eq('Contact added')
        end
      end
    end
  end

  describe '#batch_subscribe' do
    it 'should call `contact_sync` 3 times' do
      expect(client).to receive(:contact_sync).exactly(2).times

      VCR.use_cassette(cassette_base + '/contact_sync_with_name') do
        subscribers = [{ email: 'raj.kumar+99@crossover.com', name: 'R K' },
                       { email: 'raj.kumar+98@crossover.com', name: 'RK' }]
        service_provider.batch_subscribe(nil, subscribers)
      end
    end
  end
end
