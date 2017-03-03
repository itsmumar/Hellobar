require 'spec_helper'

describe ServiceProviders::MailChimp do
  let(:identity) { Identity.new(:provider => 'mailchimp', :extra => { 'metadata' => {} }, :credentials => {}) }
  let(:service_provider) { identity.service_provider }
  let(:client) { service_provider.instance_variable_get(:@client) }

  describe 'subscribe' do
    it 'catches -100 errors (email invalid)' do
      error = Gibbon::MailChimpError.new('', :status_code => -100)
      allow(client).to receive(:lists).and_raise(error)
      expect { service_provider.subscribe('123', 'abc') }.not_to raise_error
    end

    it 'catches 214 errors (email already exists)' do
      error = Gibbon::MailChimpError.new('', :status_code => 214)
      allow(client).to receive(:lists).and_raise(error)
      expect { service_provider.subscribe('123', 'abc') }.not_to raise_error
    end
  end
end
