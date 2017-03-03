require 'spec_helper'

describe ServiceProviders::VerticalResponseApi do
  let(:identity) { Identity.new(provider: 'verticalresponse', extra: { 'metadata' => {} }, credentials: {}) }
  let(:service_provider) { identity.service_provider }
  let(:client) { service_provider.instance_variable_get(:@client) }

  describe 'subscribe' do
    it 'catches VR errors' do
      allow(client).to receive(:find_list).and_raise(VerticalResponse::API::Error)
      expect { service_provider.subscribe('123', 'abc') }.not_to raise_error
    end

    it 'does not log duplicate email errors' do
      allow(client).to receive(:find_list).and_raise(VerticalResponse::API::Error.new('Contact already exists.'))
      expect(service_provider).not_to receive(:log)

      service_provider.subscribe('123', 'abc')
    end

    it 'logs non duplicate email errors' do
      allow(client).to receive(:find_list).and_raise(VerticalResponse::API::Error.new('Everything is really really bad'))
      expect(service_provider).to receive(:log)

      service_provider.subscribe('123', 'abc')
    end

    it 'uses correct params when email is present' do
      mock_list = double :list
      allow(client).to receive(:find_list).and_return(mock_list)
      expect(mock_list).to receive(:create_contact).
        with(email: 'bobloblaw@lawblog.co', first_name: 'Bob', last_name: 'Loblaw')
      service_provider.subscribe('123', 'bobloblaw@lawblog.co', 'Bob Loblaw')
    end

    it 'uses blank name if it is absent' do
      mock_list = double :list
      allow(client).to receive(:find_list).and_return(mock_list)
      expect(mock_list).to receive(:create_contact).
        with(email: 'bobloblaw@lawblog.co', first_name: '', last_name: '')
      service_provider.subscribe('123', 'bobloblaw@lawblog.co')
    end
  end
end
