describe DynamoDB do
  let(:expires_in) { 1.hour }
  let(:cache_key) { 'cache_key' }
  let(:db) { DynamoDB.new(cache_key: cache_key, expires_in: expires_in) }
  let(:client) { Aws::DynamoDB::Client.new }

  before { allow(Aws::DynamoDB::Client).to receive(:new).and_return client }

  describe '#fetch' do
    let(:fetch) { db.fetch({}) }
    let(:items) { [Hash['foo' => 'foo', 'bar' => 'bar']] }

    let(:response) do
      double(
        items: items,
        count: 0,
        scanned_count: 0,
        last_evaluated_key: nil,
        consumed_capacity: nil
      )
    end

    it 'returns array of items' do
      expect(client).to receive(:query).and_return(response)
      expect(fetch).to eql items
    end

    it 'tries to fetch cache' do
      expect(Rails.cache).to receive(:fetch).with "DynamoDB/#{ cache_key }", expires_in: expires_in
      fetch
    end

    context 'when Aws::DynamoDB::Errors::ServiceError' do
      before do
        allow(client)
          .to receive(:query).and_raise Aws::DynamoDB::Errors::ServiceError.new('', '')
      end

      specify do
        expect { fetch }.to raise_error Aws::DynamoDB::Errors::ServiceError
      end

      context 'when production' do
        before { allow(Rails.env).to receive(:test?).and_return false }

        specify do
          expect { fetch }.not_to raise_error
        end

        it 'sends error to Sentry' do
          args = [instance_of(Aws::DynamoDB::Errors::ServiceError), context: { request: anything }]
          expect(Raven).to receive(:capture_exception).with(*args)
          fetch
        end
      end
    end
  end

  describe '#batch_fetch' do
    let(:batch_fetch) { db.batch_fetch({}) }
    let(:items) { [Hash['foo' => 'foo', 'bar' => 'bar']] }
    let(:responses) { Hash[table_name: items] }

    let(:response) do
      double(
        responses: responses,
        count: 0,
        scanned_count: 0,
        last_evaluated_key: nil,
        consumed_capacity: nil
      )
    end

    it 'returns array of items' do
      expect(client).to receive(:batch_get_item).and_return(response)
      expect(batch_fetch).to eql table_name: items
    end

    it 'tries to fetch cache' do
      expect(Rails.cache).to receive(:fetch).with "DynamoDB/#{ cache_key }", expires_in: expires_in
      batch_fetch
    end

    context 'when Aws::DynamoDB::Errors::ServiceError' do
      before do
        allow(client)
          .to receive(:batch_get_item).and_raise Aws::DynamoDB::Errors::ServiceError.new('', '')
      end

      specify do
        expect { batch_fetch }.to raise_error Aws::DynamoDB::Errors::ServiceError
      end

      context 'when production' do
        before { allow(Rails.env).to receive(:test?).and_return false }

        specify do
          expect { batch_fetch }.not_to raise_error
        end

        it 'sends error to Sentry' do
          args = [instance_of(Aws::DynamoDB::Errors::ServiceError), context: { request: anything }]
          expect(Raven).to receive(:capture_exception).with(*args)
          batch_fetch
        end
      end
    end
  end
end
