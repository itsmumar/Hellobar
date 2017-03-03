require 'spec_helper'

describe ServiceProviders::AWeber do
  let(:identity) do
    Identity.new(
      provider: 'aweber', extra: { 'metadata' => {} },
      credentials: { 'token' => 'test-token', 'secret' => 'test-secret' }
    )
  end
  let(:contact_list) { ContactList.new(identity: identity, data: { 'tags' => ['test-tag1', 'test-tag2'] }) }
  let(:service_provider) { identity.service_provider(contact_list: contact_list) }
  let(:client) { service_provider.instance_variable_get(:@client) }

  VCR.configure do |c|
    c.default_cassette_options = {
      match_requests_on: [
        :method,
        VCR.request_matchers.uri_without_param(:oauth_timestamp, :oauth_nonce, :oauth_signature, :oauth_signature_method)
      ]
    }
  end

  describe 'subscribe' do
    it 'catches AWeber::CreationError errors' do
      allow(client).to receive(:account).and_raise(AWeber::CreationError)
      expect { service_provider.subscribe('123', 'abc') }.not_to raise_error
    end

    it 'a contact with tags' do
      contact = service_provider.subscribe('4567456', 'raj.kumar+7@crossover.com')
      expect(contact.class).to eq(AWeber::Resources::Subscriber)
      expect(contact.tags.count).to eq(contact_list.tags.count)
    end
  end
end
