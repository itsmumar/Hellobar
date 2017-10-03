describe FetchContacts do
  let!(:contact_list) { create :contact_list }
  let(:limit) { 5 }
  let(:service) { FetchContacts.new(contact_list, limit: limit) }

  describe '#call', freeze: true do
    let!(:request) do
      body = {
        'Items': [
          {
            'email' => { 'S': 'email@example.com' },
            'n' => { 'S': 'Name' },
            'ts' => { 'N': Time.current.to_i }
          }
        ],
        'ConsumedCapacity': {}
      }

      stub_request(:post, 'https://dynamodb.us-east-1.amazonaws.com/')
        .with(
          body: %r{"TableName":"development_contacts".+"IndexName":"ts-index".+"Limit":#{ limit }},
          headers: { 'X-Amz-Target' => 'DynamoDB_20120810.Query' }
        ).and_return(body: body.to_json)
    end

    it 'sends query to DynamoDB' do
      service.call
      expect(request).to have_been_made
    end

    it 'returns array of email:, name:, subscribed_at:' do
      expect(service.call).to match_array(
        [{ email: 'email@example.com', name: 'Name', subscribed_at: Time.current }]
      )
    end
  end
end
