describe Diamond::Client do
  let(:endpoint) { 'http://foobar.com/hbprod' }
  let(:client) { described_class.new(endpoint: endpoint) }
  let(:tracking_url) { "#{ endpoint }/t" }
  let(:headers) { { 'Accept': '*/*', 'Content-Type': 'application/json' } }

  describe '#track' do
    subject(:track) { client.track(params) }

    context 'when identities is nil' do
      let(:params) { { identities: nil, timestamp: Time.current } }

      it 'raises a TypeError' do
        expect { track }.to raise_error(TypeError, 'Must provide identities as a Hash')
      end
    end

    context 'when identities is empty' do
      let(:params) { { identities: {}, timestamp: Time.current } }

      it 'raises an ArgumentError' do
        expect { track }.to raise_error(ArgumentError, 'Must provide at least one identity')
      end
    end

    context 'when full params are provided' do
      let(:params) { { event: :foo, identities: { user_id: 123 }, timestamp: Time.current, properties: { foo: :bar } } }

      it 'sends the tracking request' do
        stub_request(:post, tracking_url).with(
          headers: headers,
          body: {
            event: 'foo',
            identities: { user_id: 123 },
            timestamp: params[:timestamp].to_f,
            properties: { foo: 'bar' }
          }.to_json
        )

        track
      end
    end

    context 'when no event is passed in' do
      let(:params) { { identities: { user_id: 123 }, timestamp: Time.current, properties: { foo: :bar } } }

      it 'tracks the request' do
        stub_request(:post, tracking_url).with(
          headers: headers,
          body: {
            identities: { user_id: 123 },
            timestamp: params[:timestamp].to_f,
            properties: { foo: 'bar' }
          }.to_json
        )

        track
      end
    end

    context 'when no properties are passed in' do
      let(:params) { { event: :foo, identities: { user_id: 123 }, timestamp: Time.current } }

      it 'tracks the request' do
        stub_request(:post, tracking_url).with(
          headers: headers,
          body: {
            event: 'foo',
            identities: { user_id: 123 },
            timestamp: params[:timestamp].to_f,
            properties: {}
          }.to_json
        )

        track
      end
    end
  end
end
