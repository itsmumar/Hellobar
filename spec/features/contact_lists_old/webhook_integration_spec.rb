require 'integration_helper'
require 'service_provider_integration_helper'

feature 'Webhook Integration' do
  include_context 'service provider request setup'

  let(:provider)         { 'webhooks' }
  let(:api_domain)       { 'hellobar.com' }

  context 'GET request webhook' do
    let(:contact_list) { build(:contact_list, data: { 'webhook_url' => url, 'webhook_method' => 'get' }) }

    it 'sends parameters in the URL' do
      request = a_request(:get, /.*hellobar.com.*/).with(query: hash_including(name: name, email: email))
      expect(request).to have_been_made.once
    end
  end

  context 'POST request webhook' do
    let(:contact_list) { build(:contact_list, data: { 'webhook_url' => url, 'webhook_method' => 'post' }) }

    it 'sends parameters in the post payload' do
      request = a_request(:post, /.*hellobar.com.*/).with(body: hash_including(name: name, email: email))
      expect(request).to have_been_made.once
    end
  end
end
