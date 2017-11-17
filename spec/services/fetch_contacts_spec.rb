describe FetchContacts do
  let!(:contact_list) { create :contact_list }
  let(:limit) { 5 }
  let(:service) { FetchContacts.new(contact_list, limit: limit) }

  describe '#call', freeze: true do
    let(:name) { 'Name' }
    let(:email) { 'email@example.com' }
    let(:status) { 'error' }
    let(:error) { 'Email is blacklisted' }
    let(:body) do
      {
        'Items': [
          {
            'email' => { 'S': email },
            'n' => { 'S': name },
            'ts' => { 'N': Time.current.to_i },
            'status' => { 'S' => status },
            'error' => { 'S' => error }
          }
        ],
        'ConsumedCapacity': {}
      }
    end

    let!(:request) do
      stub_request(:post, 'https://dynamodb.us-east-1.amazonaws.com/')
        .with(
          body: %r{"TableName":"development_contacts".+"Limit":#{ limit }},
          headers: { 'X-Amz-Target' => 'DynamoDB_20120810.Query' }
        ).and_return(body: body.to_json)
    end

    it 'sends query to DynamoDB' do
      service.call

      expect(request).to have_been_made
    end

    it 'returns array of email, name, subscribed_at, status and error' do
      expect(service.call).to match_array([{
        email: email,
        name: name,
        subscribed_at: Time.current,
        status: status,
        error: error
      }])
    end
  end
end
