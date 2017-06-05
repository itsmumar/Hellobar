describe ServiceProviders::Adapters do
  let(:adapters) { described_class }
  let(:all) do
    {
      aweber: ServiceProviders::Adapters::Aweber,
      active_campaign: ServiceProviders::Adapters::ActiveCampaign,
      createsend: ServiceProviders::Adapters::CampaignMonitor,
      constantcontact: ServiceProviders::Adapters::ConstantContact,
      convert_kit: ServiceProviders::Adapters::ConvertKit,
      drip: ServiceProviders::Adapters::Drip,
      get_response_api: ServiceProviders::Adapters::GetResponse,
      icontact: ServiceProviders::Adapters::IContact,
      infusionsoft: ServiceProviders::Adapters::Infusionsoft,
      mad_mimi_api: ServiceProviders::Adapters::MadMimi,
      mad_mimi_form: ServiceProviders::Adapters::MadMimiForm,
      mailchimp: ServiceProviders::Adapters::MailChimp,
      maropost: ServiceProviders::Adapters::Maropost,
      my_emma: ServiceProviders::Adapters::MyEmma,
      verticalresponse: ServiceProviders::Adapters::VerticalResponse,
      vertical_response: ServiceProviders::Adapters::VerticalResponseForm,
      webhooks: ServiceProviders::Adapters::Webhook
    }
  end

  describe '.fetch' do
    it 'returns registered adapter class by key' do
      expect(adapters.fetch(:aweber)).to be ServiceProviders::Adapters::Aweber
    end
  end

  describe '.registry' do
    it 'returns all adapter classes' do
      expect(adapters.registry).to match all
    end
  end

  describe '.register' do
    let(:foo) { Class.new(ServiceProviders::Adapters::Base) }

    after { adapters.registry.delete(:foo) }

    it 'adds adapter class to registry' do
      adapters.register :foo, foo
      expect(adapters.fetch(:foo)).to be foo
    end

    it 'assigns key to adapter' do
      adapters.register :foo, foo
      expect(foo.key).to eql :foo
    end
  end

  describe '.keys' do
    it 'returns keys for all adapters' do
      expect(adapters.keys).to match_array all.keys
    end
  end

  describe '.all' do
    it 'returns classes for all adapters' do
      expect(adapters.all).to match_array all.values
    end
  end

  describe '.enabled' do
    let(:disabled) { [ServiceProviders::Adapters::MadMimiForm, ServiceProviders::Adapters::VerticalResponseForm] }

    it 'returns not hidden adapters' do
      expect(adapters.enabled).to match_array all.values - disabled
    end
  end
end
