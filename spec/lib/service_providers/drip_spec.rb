require "integration_helper"

describe ServiceProviders::Drip do
  let(:identity) { Identity.new(provider: 'drip', credentials: { 'token' => 'fake_key', 'expires' => false}, extra: {'account_id' => '4773344', 'account_name' => 'www.nutritionsecrets.com'}) }
  let(:contact_list) { ContactList.new }
  let(:service_provider) { identity.service_provider}
  let(:client) { service_provider.instance_variable_get(:@client) }
  let(:drip_endpoint) { "https://api.getdrip.com/v2" }

  describe '#accounts' do
    it 'should return list of accounts' do
      VCR.use_cassette('service_providers/drip/accounts') do
        accounts = service_provider.accounts
        expect(accounts.count).to eq(1)
      end
    end
  end

  describe '#campaigns' do
    it 'should return list of campaigns' do
      service_provider.instance_variable_set(:@contact_list, contact_list)

      VCR.use_cassette('service_providers/drip/campaigns') do
        campaigns = service_provider.campaigns
        expect(campaigns.count).to eq(3)
      end
    end
  end

  describe '#tags' do
    it 'should return list of tags' do
      VCR.use_cassette('service_providers/drip/tags') do
        tags = service_provider.tags
        expect(tags.count).to eq(3)
      end
    end
  end

  describe '#subscribe' do
    it 'should subscribe to the campaign' do
      service_provider.instance_variable_set(:@contact_list, contact_list)
      subscribe_url = "#{drip_endpoint}/#{identity.extra['account_id']}/campaigns/81207609/subscribers"

      VCR.use_cassette('service_providers/drip/subscribe_cpn_id') do
        service_provider.subscribe('81207609', 'raj.kumar+7@crossover.com', 'Test Mname User', false)
        WebMock.should have_requested(:post, subscribe_url)
      end
    end

    it 'should subscribe to the campaign with tags' do
      tags = ['TestTag1', 'TestTag2']
      contact_list.data['tags'] = tags
      service_provider.instance_variable_set(:@contact_list, contact_list)
      subscribe_url = "#{drip_endpoint}/#{identity.extra['account_id']}/campaigns/98654057/subscribers"

      VCR.use_cassette('service_providers/drip/subscribe_with_tags') do
        service_provider.subscribe('98654057', 'raj.kumar+9@crossover.com', 'Test Mname User', false)

        WebMock.should have_requested(:post, subscribe_url).with { |req|
          JSON.parse(req.body) == {
            "subscribers" => [{
              "new_email" => "raj.kumar+9@crossover.com",
              "tags" => ["TestTag1", "TestTag2"],
              "custom_fields" => {
                "name" => "Test Mname User",
                "fname" => "Test",
                "lname" => "Mname User"
              },
              "double_optin" => false,
              "email" => "raj.kumar+9@crossover.com"
            }]
          }
        }
      end
    end

    it 'should subscribe to the parent account' do
      service_provider.instance_variable_set(:@contact_list, contact_list)
      subscribe_url = "#{drip_endpoint}/#{identity.extra['account_id']}/subscribers"

      VCR.use_cassette('service_providers/drip/subscribe_account') do
        service_provider.subscribe(nil, 'raj.kumar+6@crossover.com', 'Test Mname User', false)
        WebMock.should have_requested(:post, subscribe_url)
      end
    end
  end
end
