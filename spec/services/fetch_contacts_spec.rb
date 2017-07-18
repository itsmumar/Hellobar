describe FetchContacts do
  let!(:contact_list) { create :contact_list }
  let(:service) { FetchContacts.new(contact_list, limit: 5) }

  describe '#call', freeze: true do
    let!(:request) do
      body = {
        'Items': [
          { 'email' => { 'S': 'email@example.com' }, 'n' => { 'S': 'Name' }, 'ts' => { 'N': Time.current.to_i } },
        ]
      }

      stub_request(:post, 'https://dynamodb.us-east-1.amazonaws.com/')
        .with(
          body: /"TableName":"edge_contacts"/,
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

    context 'when Aws::DynamoDB::Errors::ServiceError is raised' do
      before do
        allow_any_instance_of(Aws::DynamoDB::Client)
          .to receive(:query).and_raise(Aws::DynamoDB::Errors::ServiceError.new(double('context'), 'message'))
        allow(Rails.env).to receive(:test?).and_return false
      end

      it 'sends error to Raven' do
        expect(Raven)
          .to receive(:capture_exception)
          .with(an_instance_of(Aws::DynamoDB::Errors::ServiceError), context: { request: instance_of(Hash) })

        service.call
      end

      it 'returns []' do
        expect(service.call).to eql []
      end
    end
  end
end
