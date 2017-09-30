describe DynamoDB do
  describe '#update_item' do
    let(:capacity_units) { 1.0 }
    let(:table_name) { 'table' }
    let(:id) { 5 }

    let(:consumed_capacity) do
      Aws::DynamoDB::Types::ConsumedCapacity.new(
        capacity_units: capacity_units,
        table_name: table_name
      )
    end

    let(:update_item_response) do
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
          update_item: update_item_response
        }
      )
    end

    let(:dynamo_db) { DynamoDB.new }

    before do
      expect(Aws::DynamoDB::Client).to receive(:new).and_return client
    end

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
