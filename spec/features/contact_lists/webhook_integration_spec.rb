require 'integration_helper'
require 'service_provider_integration_helper'

feature 'Webhook Integration' do
  include_context 'service provider request setup'

  let(:provider)         { 'webhooks' }
  let(:api_domain)       { 'hellobar.com' }
  let(:service_provider) { identity.service_provider(contact_list: contact_list) }

  context 'GET request webhook' do
    let(:contact_list) { build(:contact_list, data: { 'webhook_url' => url, 'webhook_method' => 'get' }) }

    it 'sends parameters in the URL' do
      expect(a_request(:get, /.*hellobar.com.*/).
               with(query: hash_including(name: name, email: email))
      ).to have_been_made.once
    end
  end

  context 'POST request webhook' do
    let(:contact_list) { build(:contact_list, data: { 'webhook_url' => url, 'webhook_method' => 'post' }) }

    it 'sends parameters in the post payload' do
      expect(a_request(:post, /.*hellobar.com.*/).
               with(body: hash_including(name: name, email: email))
      ).to have_been_made.once
    end
  end
end
