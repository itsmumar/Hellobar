describe ServiceProviders::Adapters::Infusionsoft, :no_vcr do
  define_urls(
    subscribe: 'https://api.infusionsoft.com/crm/rest/v1/{port}/api/xmlrpc',
    optin: 'https://api.infusionsoft.com/crm/rest/v1/{port}/api/xmlrpc'
  )

  let(:config_source) { double('config_source', api_key: 'api_key', extra: { 'app_url' => 'api.infusionsoft.com/crm/rest/v1/' }) }
  let(:adapter) { described_class.new(config_source) }
  let(:list_id) { 4567456 }

  describe '#initialize' do
    it 'initializes Infusionsoft' do
      expect(::Infusionsoft::Client).to receive(:new).with(
        api_url: 'api.infusionsoft.com/crm/rest/v1/',
        api_key: 'api_key',
        api_logger: instance_of(Logger)
      ).and_call_original
      expect(adapter.client).to be_a ::Infusionsoft::Client
    end
  end

  describe '#lists', skip: 'infusionsoft does not have lists' do
  end

  describe '#subscribe' do
    body = "<?xml version=\"1.0\" ?><methodCall><methodName>ContactService.addWithDupCheck</methodName><params><param><value><string>api_key</string></value></param><param><value><struct><member><name>Email</name><value><string>example@email.com</string></value></member></struct></value></param><param><value><string>Email</string></value></param></params></methodCall>\n"

    allow_request :post, :subscribe, body: body do |stub|
      let(:subscribe_request) { stub }
    end

    body = "<?xml version=\"1.0\" ?><methodCall><methodName>APIEmailService.optIn</methodName><params><param><value><string>api_key</string></value></param><param><value><string>example@email.com</string></value></param><param><value><string>requested information</string></value></param></params></methodCall>\n"
    allow_request :post, :optin, body: body

    it 'sends subscribe request' do
      adapter.subscribe(list_id, email: 'example@email.com')
      expect(subscribe_request).to have_been_made
    end
  end

  describe '#batch_subscribe' do
    let(:subscribers) { [{ email: 'example1@email.com' }, { email: 'example2@email.com' }] }

    it 'calls #subscribe for each subscriber' do
      subscribers.each do |subscriber|
        expect(adapter).to receive(:subscribe).with('list_id', subscriber)
      end
      adapter.batch_subscribe 'list_id', subscribers
    end
  end
end
