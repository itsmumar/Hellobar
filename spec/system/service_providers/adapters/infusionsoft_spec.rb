describe ServiceProviders::Adapters::Infusionsoft do
  let(:defined_urls) do
    {
      subscribe: 'https://api.infusionsoft.com/crm/rest/v1/{port}/api/xmlrpc',
      optin: 'https://api.infusionsoft.com/crm/rest/v1/{port}/api/xmlrpc',
      add_to_group: 'https://api.infusionsoft.com/crm/rest/v1/{port}/api/xmlrpc'
    }
  end

  let(:identity) { double('identity', provider: 'infusionsoft', api_key: 'api_key', extra: { 'app_url' => 'api.infusionsoft.com/crm/rest/v1/' }) }

  include_examples 'service provider'

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
    let(:body) { "<?xml version=\"1.0\" ?><methodCall><methodName>ContactService.addWithDupCheck</methodName><params><param><value><string>api_key</string></value></param><param><value><struct><member><name>Email</name><value><string>example@email.com</string></value></member><member><name>FirstName</name><value><string>FirstName</string></value></member><member><name>LastName</name><value><string>LastName</string></value></member></struct></value></param><param><value><string>EmailAndName</string></value></param></params></methodCall>\n" }
    let(:optin_body) { "<?xml version=\"1.0\" ?><methodCall><methodName>APIEmailService.optIn</methodName><params><param><value><string>api_key</string></value></param><param><value><string>example@email.com</string></value></param><param><value><string>requested information</string></value></param></params></methodCall>\n" }
    let(:add_to_group_body_tag1) { "<?xml version=\"1.0\" ?><methodCall><methodName>ContactService.addToGroup</methodName><params><param><value><string>api_key</string></value></param><param><value><i4>1234</i4></value></param><param><value><string>id1</string></value></param></params></methodCall>\n" }
    let(:add_to_group_body_tag2) { "<?xml version=\"1.0\" ?><methodCall><methodName>ContactService.addToGroup</methodName><params><param><value><string>api_key</string></value></param><param><value><i4>1234</i4></value></param><param><value><string>id2</string></value></param></params></methodCall>\n" }

    let!(:subscribe_request) { allow_request :post, :subscribe, body: body }

    before do
      allow_request :post, :optin, body: optin_body
      allow_request :post, :add_to_group, body: add_to_group_body_tag1
      allow_request :post, :add_to_group, body: add_to_group_body_tag2
    end

    it 'sends subscribe request' do
      provider.subscribe(list_id, email: email, name: name)
      expect(subscribe_request).to have_been_made
    end
  end

  describe '#batch_subscribe' do
    let(:subscribers) { [{ email: 'example1@email.com' }, { email: 'example2@email.com' }] }

    it 'calls #subscribe for each subscriber' do
      subscribers.each do |subscriber|
        expect(adapter).to receive(:subscribe).with(list_id, subscriber.merge(double_optin: true))
      end
      provider.batch_subscribe list_id, subscribers
    end
  end
end
