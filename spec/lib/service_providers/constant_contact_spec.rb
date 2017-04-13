describe ServiceProviders::ConstantContact do
  let(:credentials) { { 'token' => '15319244-a98b-45a2-814b-704a632095e7' } }
  let(:identity) { Identity.new(provider: 'constantcontact', extra: {}, credentials: credentials) }
  let(:service_provider) { identity.service_provider }
  let(:client) { service_provider.instance_variable_get(:@client) }

  describe 'lists' do
    it 'returns available lists', :vcr do
      expect(service_provider.lists).to eql [
        { 'id' => '1552534540', 'name' => 'General Interest' },
        { 'id' => '1139133042', 'name' => 'Test_hellobar' }
      ]
    end
  end

  def bad_request(message)
    net_http_res = OpenStruct.new(body: message, code: 400)
    response = RestClient::Response.create(message, net_http_res, nil, nil)
    RestClient::BadRequest.new(response)
  end

  describe 'subscribe' do
    context 'when conflicts' do
      before do
        service_provider.subscribe('1552534540', 'anton.sozontov@crossover.com')
      end

      it 'updates record duplicate email', :vcr do
        expect(service_provider.subscribe('1552534540', 'anton.sozontov@crossover.com')). to be_truthy
      end

      context 'when conflicts again' do
        it 'returns true', :vcr do
          allow(client).to receive(:update_contact).and_raise RestClient::Conflict
          expect(service_provider.subscribe('1552534540', 'anton.sozontov@crossover.com')). to be_truthy
        end
      end

      context 'and ask for double opt-in' do
        it 'retries with double opt-in', :vcr do
          allow(client)
            .to receive(:update_contact)
            .with(credentials['token'], instance_of(ConstantContact::Components::Contact), false)
            .and_raise bad_request('not be opted in using')

          expect(client)
            .to receive(:update_contact)
            .with(credentials['token'], instance_of(ConstantContact::Components::Contact), true)
            .and_return(true)

          expect(service_provider.subscribe('1552534540', 'anton.sozontov@crossover.com', '', false)). to be_truthy
        end
      end
    end

    context 'when email is valid' do
      it 'returns true', :vcr do
        expect(client).to receive(:add_contact)
          .with(credentials['token'], instance_of(ConstantContact::Components::Contact), true)
        service_provider.subscribe('1552534540', 'bobloblaw@lawblog.co', 'Bob Loblaw', true)
      end

      context 'and ask for double opt-in' do
        it 'retries with double opt-in', :vcr do
          allow(client)
            .to receive(:add_contact)
            .with(credentials['token'], instance_of(ConstantContact::Components::Contact), false)
            .and_raise bad_request('not be opted in using')

          expect(client)
            .to receive(:add_contact)
            .with(credentials['token'], instance_of(ConstantContact::Components::Contact), true)
            .and_return(true)

          expect(service_provider.subscribe('1552534540', 'bobloblaw@lawblog.co', '', false)). to be_truthy
        end
      end
    end

    context 'when email is invalid' do
      it 'returns true', :vcr do
        allow(client).to receive(:add_contact)
          .with(credentials['token'], instance_of(ConstantContact::Components::Contact), true)
          .and_raise bad_request('not a valid email address')
        expect(service_provider.subscribe('1552534540', '@lawblog.co', 'Bob Loblaw', true)).to be_truthy
      end
    end
  end

  describe 'batch_subscribe' do
    it 'returns ConstantContact::Components::Activity', :vcr do
      subscribers = [email: 'anton.sozontov@crossover.com', name: 'Anton']
      expect(service_provider.batch_subscribe('1552534540', subscribers)).to be_a ConstantContact::Components::Activity
    end
  end
end
