describe ServiceProvider::Adapters do
  let(:adapters) { described_class }
  let(:all) do
    {
      hellobar: ServiceProvider::Adapters::Hellobar,
      aweber: ServiceProvider::Adapters::Aweber,
      active_campaign: ServiceProvider::Adapters::ActiveCampaign,
      createsend: ServiceProvider::Adapters::CampaignMonitor,
      constantcontact: ServiceProvider::Adapters::ConstantContact,
      convert_kit: ServiceProvider::Adapters::ConvertKit,
      drip: ServiceProvider::Adapters::Drip,
      get_response_api: ServiceProvider::Adapters::GetResponse,
      icontact: ServiceProvider::Adapters::IContact,
      infusionsoft: ServiceProvider::Adapters::Infusionsoft,
      mad_mimi_api: ServiceProvider::Adapters::MadMimi,
      mad_mimi_form: ServiceProvider::Adapters::MadMimiForm,
      mailchimp: ServiceProvider::Adapters::MailChimp,
      maropost: ServiceProvider::Adapters::Maropost,
      my_emma: ServiceProvider::Adapters::MyEmma,
      verticalresponse: ServiceProvider::Adapters::VerticalResponse,
      vertical_response: ServiceProvider::Adapters::VerticalResponseForm,
      webhooks: ServiceProvider::Adapters::Webhook
    }
  end

  describe '.embed_code?' do
    specify do
      allow(adapters).to receive(:exists?).and_return(true)
      allow(adapters).to receive(:fetch).and_return(double(config: double(requires_embed_code: true)))
      expect(adapters.embed_code?(:foo)).to be_truthy
    end
  end

  describe '.fetch' do
    it 'returns registered adapter class by key' do
      expect(adapters.fetch(:aweber)).to be ServiceProvider::Adapters::Aweber
    end
  end

  describe '.registry' do
    it 'returns all adapter classes' do
      expect(adapters.registry).to match all
    end
  end

  describe '.register' do
    let(:foo) { Class.new(ServiceProvider::Adapters::Base) }

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
    let(:hidden) do
      [
        ServiceProvider::Adapters::Hellobar,
        ServiceProvider::Adapters::MadMimiForm,
        ServiceProvider::Adapters::VerticalResponseForm
      ]
    end

    it 'returns not hidden adapters' do
      expect(adapters.enabled).to match_array all.values - hidden
    end
  end
end
