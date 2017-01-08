require "spec_helper"

describe ServiceProviders::Drip do

  let(:identity) { Identity.new(provider: 'drip', credentials: { 'token' => 'fake_key', 'expires' => false}, extra: {'account_id' => '4773344', 'account_name' => 'www.nutritionsecrets.com'}) }
  let(:service_provider) { identity.service_provider}
  let(:client) { service_provider.instance_variable_get(:@client) }

  describe '#accounts' do
    it 'should return list of accounts' do
      VCR.use_cassette('service_providers/drip_accounts') do
        accounts = service_provider.accounts
        expect(accounts.count).to eq(1)
      end
    end
  end

  describe '#campaigns' do
    it 'should return list of campaigns' do
      VCR.use_cassette('service_providers/drip_campaigns') do
        campaigns = service_provider.campaigns
        expect(campaigns.count).to eq(3)
      end
    end
  end

  describe '#subscribe' do
    it 'should subscribe with campaign_id' do
      VCR.use_cassette('service_providers/drip_subscribe_cpn_id') do
        service_provider.subscribe('81207609', 'raj.kumar+7@crossover.com', 'Test Mname User', false)
        WebMock.should have_requested(:post, "https://api.getdrip.com/v2/#{identity.extra['account_id']}/campaigns/81207609/subscribers")
      end
    end

    it 'should subscribe without campaign_id' do
      VCR.use_cassette('service_providers/drip_subscribe_account') do
        service_provider.subscribe(nil, 'raj.kumar+6@crossover.com', 'Test Mname User', false)
        WebMock.should have_requested(:post, "https://api.getdrip.com/v2/#{identity.extra['account_id']}/subscribers")
      end
    end
  end

end
