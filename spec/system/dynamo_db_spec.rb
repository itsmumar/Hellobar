describe DynamoDB do
  describe '#update_item' do
    it 'sends #update_item POST request to DynamoDB' do
      id = 5
      table_name = 'table'

      params = {
        key: {
          id: id
        },
        table_name: table_name
      }

      dynamo_params = {
        Key: {
          id: {
            N: id.to_s
          }
        },
        TableName: table_name
      }

      dynamo_db = DynamoDB.new

      stub_request(:post, 'https://dynamodb.us-east-1.amazonaws.com')
        .with(body: dynamo_params.to_json)

      dynamo_db.update_item params
    end
  end
end
