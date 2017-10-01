describe DynamoDB do
  let(:capacity_units) { 1.0 }
  let(:table_name) { 'table' }
  let(:id) { 5 }
  let(:expires_in) { 1.hour }
  let(:cache_key) { 'cache_key' }
  let(:items) { [Hash['foo' => 'foo', 'bar' => 'bar']] }
  let(:count) { items.size }

  let(:consumed_capacity) do
    Aws::DynamoDB::Types::ConsumedCapacity.new(
      capacity_units: capacity_units,
      table_name: table_name
    )
  end

  let(:query_output) do
    Aws::DynamoDB::Types::QueryOutput.new(
      items: items,
      consumed_capacity: consumed_capacity,
      count: count
    )
  end

  let(:batch_get_item_output) do
    Aws::DynamoDB::Types::BatchGetItemOutput.new(
      responses: {
        table_name => items
      },
      consumed_capacity: consumed_capacity
    )
  end

  let(:update_item_output) do
    Aws::DynamoDB::Types::UpdateItemOutput.new(
      attributes: {
        id: id
      },
      consumed_capacity: consumed_capacity
    )
  end

  let(:client) do
    Aws::DynamoDB::Client.new(
      stub_responses: {
        query: query_output,
        batch_get_item: batch_get_item_output,
        update_item: update_item_output
      }
    )
  end

  let(:dynamo_db) { DynamoDB.new cache_key: cache_key, expires_in: expires_in }

  before do
    allow(Aws::DynamoDB::Client).to receive(:new).and_return client
  end

  describe '.contacts_table_name' do
    it 'returns appropriate table name for the staging environment' do
      expect(Rails).to receive(:env).and_return 'staging'
      expect(DynamoDB.contacts_table_name).to eq 'staging_contacts'
    end

    it 'returns appropriate table name for the production environment' do
      expect(Rails).to receive(:env).and_return 'production'
      expect(DynamoDB.contacts_table_name).to eq 'contacts'
    end

    it 'returns appropriate table name for the edge environment' do
      expect(Rails).to receive(:env).and_return 'edge'
      expect(DynamoDB.contacts_table_name).to eq 'edge_contacts'
    end

    it 'returns appropriate table name for the test environment' do
      expect(DynamoDB.contacts_table_name).to eq 'development_contacts'
    end
  end

  describe '.visits_table_name' do
    it 'returns appropriate table name for the staging environment' do
      expect(Rails).to receive(:env).and_return 'staging'
      expect(DynamoDB.visits_table_name).to eq 'staging_over_time'
    end

    it 'returns appropriate table name for the production environment' do
      expect(Rails).to receive(:env).and_return 'production'
      expect(DynamoDB.visits_table_name).to eq 'over_time'
    end

    it 'returns appropriate table name for the edge environment' do
      expect(Rails).to receive(:env).and_return 'edge'
      expect(DynamoDB.visits_table_name).to eq 'edge_over_time2'
    end

    it 'returns appropriate table name for the test environment' do
      expect(DynamoDB.visits_table_name).to eq 'edge_over_time2'
    end
  end

  describe '#query' do
    let(:params) { Hash[table_name: table_name] }
    let(:query) { dynamo_db.query params }

    it 'returns array of items' do
      expect(query).to eql items
    end

    it 'tries to fetch from the Rails cache without querying DynamoDB' do
      expect(Aws::DynamoDB::Client).not_to receive :new
      expect(Rails.cache).to receive(:fetch)
        .with "DynamoDB/#{ cache_key }", expires_in: expires_in

      query
    end

    context 'when Aws::DynamoDB::Errors::ServiceError is raised' do
      before do
        allow(client).to receive(:query)
          .and_raise Aws::DynamoDB::Errors::ServiceError.new '', ''
      end

      it 'raises an error' do
        expect { query }
          .to raise_error Aws::DynamoDB::Errors::ServiceError
      end

      context 'when production' do
        before do
          allow(Rails.env).to receive(:test?).and_return false
        end

        it 'does not raise an error' do
          expect { query }.not_to raise_error
        end

        it 'sends error to Sentry' do
          args = [
            instance_of(Aws::DynamoDB::Errors::ServiceError),
            context: {
              request: anything
            }
          ]

          expect(Raven).to receive(:capture_exception).with(*args)

          query
        end
      end
    end
  end

  describe '#batch_get_item' do
    let(:params) do
      {
        request_items: {
          table_name => {
            keys: [
              { id: id }
            ]
          }
        }
      }
    end

    let(:batch_get_item) { dynamo_db.batch_get_item params }
    let(:responses) { Hash[table_name: items] }

    it 'returns an array of items' do
      expect(batch_get_item).to eql table_name => items
    end

    it 'tries to fetch from the Rails cache without querying DynamoDB' do
      expect(Aws::DynamoDB::Client).not_to receive :new
      expect(Rails.cache).to receive(:fetch)
        .with "DynamoDB/#{ cache_key }", expires_in: expires_in

      batch_get_item
    end

    context 'when Aws::DynamoDB::Errors::ServiceError is raised' do
      before do
        allow(client).to receive(:batch_get_item)
          .and_raise Aws::DynamoDB::Errors::ServiceError.new '', ''
      end

      specify do
        expect { batch_get_item }.to raise_error Aws::DynamoDB::Errors::ServiceError
      end

      context 'when production' do
        before { allow(Rails.env).to receive(:test?).and_return false }

        specify do
          expect { batch_get_item }.not_to raise_error
        end

        it 'sends error to Sentry' do
          args = [instance_of(Aws::DynamoDB::Errors::ServiceError), context: { request: anything }]
          expect(Raven).to receive(:capture_exception).with(*args)

          batch_get_item
        end
      end
    end
  end

  describe '#update_item' do
    it 'sends #update_item request to DynamoDB' do
      params = {
        key: {
          id: id
        },
        table_name: table_name
      }

      response = dynamo_db.update_item params

      expect(response.attributes).to eq id: id
      expect(response.consumed_capacity.table_name).to eq table_name
      expect(response.consumed_capacity.capacity_units).to eq capacity_units
    end
  end
end
