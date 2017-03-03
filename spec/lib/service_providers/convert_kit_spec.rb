require 'spec_helper'

describe ServiceProviders::ConvertKit do
  let(:identity) { Identity.new(provider: 'convert_kit', api_key: 'valid-convertkit-key') }
  let(:service_provider) { identity.service_provider }
  let(:contact_list) { ContactList.new }
  let(:client) { service_provider.instance_variable_get(:@client) }

  describe '#tags' do
    it 'should make a call to ConvertKit for their tags' do
      expect(client).to receive(:get) { double('response', success?: true, status: 200, body: { 'tags' => [] }.to_json) }
      service_provider.tags
    end
  end

  describe '#lists' do
    it 'should make a call to ConvertKit for their lists' do
      expect(client).to receive(:get) { double('response', success?: true, status: 200, body: { 'forms' => [] }.to_json) }
      service_provider.lists
    end
  end

  context 'should POST data to API' do
    before(:each) do
      @form_id, @email = '1234', 'test@test.com'
      service_provider.instance_variable_set(:@contact_list, contact_list)
      @data = { api_key: identity.api_key, email: @email, tags: '' }
      @uri = "forms/#{@form_id}/subscribe?api_secret=#{identity.api_key}"
    end

    describe '#subscribe' do
      it 'without name & tags' do
        expect(client).to receive(:post).with(@uri, @data)
        service_provider.subscribe(@form_id, @email)
      end

      it 'with first name only' do
        @data[:first_name] = 'R'
        expect(client).to receive(:post).with(@uri, @data)
        service_provider.subscribe(@form_id, @email, 'R')
      end

      it 'with first name & last name' do
        @data[:first_name] = 'R'
        @data[:fields] = { last_name: 'K' }
        expect(client).to receive(:post).with(@uri, @data)
        service_provider.subscribe(@form_id, @email, 'R K')
      end

      it 'with tags' do
        tags = { 'tags' => %w{1 2 3} }
        contact_list.data = tags
        service_provider.instance_variable_set(:@contact_list, contact_list)
        @data[:tags] = '1,2,3'
        expect(client).to receive(:post).with(@uri, @data)
        service_provider.subscribe(@form_id, @email)
      end
    end

    describe '#batch_subscribe' do
      it 'should POST data multiple times' do
        subscribers = [{ email: 'test@test.com', name: 'R K' },
                       { email: 'test1@test.com', name: 'Raj K' },
                       { email: 'test2@test.com', name: 'RK' }]
        expect(client).to receive(:post).exactly(3).times { nil }

        service_provider.batch_subscribe(@form_id, subscribers)
      end
    end
  end
end
