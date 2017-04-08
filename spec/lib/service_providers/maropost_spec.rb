describe ServiceProviders::Maropost do
  it 'raises an error if no identity is provided' do
    expect { ServiceProviders::Maropost.new }.to raise_error('Must provide an identity')
  end

  it 'raises error if identity is missing api key' do
    identity = Identity.new site_id: 1, provider: 'maropost'

    expect { ServiceProviders::Maropost.new(identity: identity) }
      .to raise_error('Identity does not have a stored Maropost API key and AccountID')
  end

  describe '#valid?' do
    let(:identity) do
      Identity.new site_id: 1,
        provider: 'maropost',
        api_key: api_key,
        credentials: { 'username' => 'a_user_id_actually' }
    end
    let(:maropost) { ServiceProviders::Maropost.new(identity: identity) }

    context 'when matches ^[A-Za-z0-9]{54}$' do
      let(:api_key) { 'TiqJgU1soKXuvaC3vDzBsRpcwxtyhBFIujI0PDgzcKKOlasZZtrZZg' }
      specify { expect(maropost).to be_valid }
    end

    context 'when length less than 54 chars' do
      let(:api_key) { 'TiqJgU1soKXuvaC3vDzBsRpcwxtyhBFIujI0PDgzcKKOlasZZtrZZ' }
      specify { expect(maropost).not_to be_valid }
    end

    context 'when contains not valid symbols' do
      let(:api_key) { '-TiqJgU1soKXuvaC3vDzBsRpcwxtyhBFIujI0PDgzcKKOlasZZtrZZ' }
      specify { expect(maropost).not_to be_valid }
    end
  end

  context 'remote requests' do
    let(:identity) do
      Identity.new site_id: 1,
                   provider: 'maropost',
                   api_key: 'TiqJgU1soKXuvaC3vDzBsRpcwxtyhBFIujI0PDgzcKKOlasZZtrZZg',
                   credentials: { 'username' => 'a_user_id_actually' }
    end

    let(:maropost) { ServiceProviders::Maropost.new(identity: identity) }
    let(:client) { Faraday.new }

    let(:success_body) {}
    let(:success_response) { double :response, success?: true, body: [{ id: 1122, name: 'myCoolList' }].to_json }

    let(:failure_response) do
      double :response,
        success?: false,
        status: 500,
        body: 'things went really bad'
    end

    before do
      allow(Faraday).to receive(:new).and_return(client)
    end

    context '#lists' do
      it 'includes auth_token in api requests' do
        expect(client)
          .to receive(:get)
          .with(anything, hash_including(auth_token: 'TiqJgU1soKXuvaC3vDzBsRpcwxtyhBFIujI0PDgzcKKOlasZZtrZZg'))
          .and_return(success_response)

        expect(maropost.lists).to eq([{ 'id' => 1122, 'name' => 'myCoolList' }])
      end

      it 'returns hash array of hashes of ids and names' do
        allow(client).to receive(:get).and_return(success_response)
        expect(maropost.lists).to eq([{ 'id' => 1122, 'name' => 'myCoolList' }])
      end

      it 'returns empty array when time out' do
        allow(client).to receive(:get).and_raise(Faraday::TimeoutError)
        expect(maropost.lists).to eq([])
      end

      it 'returns empty array in the event of failed request' do
        allow(client).to receive(:get).and_return(failure_response)
        expect(maropost.lists).to eq([])
      end

      it 'handles time out' do
        allow(client).to receive(:get).and_raise(Faraday::TimeoutError)
        expect(maropost)
          .to receive(:log)
          .with('getting lists timed out')
        maropost.lists
      end

      it 'logs parsed error message in the event of failed request' do
        allow(client).to receive(:get).and_return(failure_response)
        expect(maropost)
          .to receive(:log)
          .with("getting lists returned 'things went really bad' with the code 500")
        maropost.lists
      end
    end

    context '#subscribe' do
      it 'sends name, email and Maropost options' do
        double_request = double(:request, url: true)

        contact = { first_name: 'Bob',
                    last_name: 'Blah Loblaw',
                    email: 'bobloblaw@lawblog.com',
                    subscribe: true,
                    remove_from_dnm: true }

        expect(double_request)
          .to receive(:body=)
          .with(hash_including(contact: contact))

        allow(client).to receive(:post).and_yield(double_request)
        maropost.subscribe(1122, 'bobloblaw@lawblog.com', 'Bob Blah Loblaw')
      end

      it 'includes auth_token in api requests' do
        double_request = double(:request, url: true)

        expect(double_request)
          .to receive(:body=)
          .with(hash_including(auth_token: 'TiqJgU1soKXuvaC3vDzBsRpcwxtyhBFIujI0PDgzcKKOlasZZtrZZg'))

        allow(client).to receive(:post).and_yield(double_request)
        maropost.subscribe(1122, 'bobloblaw@lawblog.com', 'Bob')
      end

      it 'submits email address as name if name is not present' do
        double_request = double(:request, url: true)

        expect(double_request)
          .to receive(:body=) do |body|
            expect(body[:contact]).to include(first_name: 'bobloblaw@lawblog.com')
          end

        allow(client).to receive(:post).and_yield(double_request)
        maropost.subscribe(1122, 'bobloblaw@lawblog.com')
      end

      it 'logs parsed error message in the event of failed request' do
        allow(client).to receive(:post).and_return(failure_response)
        expect(maropost)
          .to receive(:log)
          .with("sync error bobloblaw@lawblog.com sync returned 'things went really bad' with the code 500")
        maropost.subscribe(1122, 'bobloblaw@lawblog.com')
      end

      it 'handles time out' do
        allow(client).to receive(:post).and_raise(Faraday::TimeoutError)
        expect(maropost)
          .to receive(:log)
          .with('sync timed out')
        maropost.subscribe(1122, 'bobloblaw@lawblog.com')
      end
    end
  end
end
