describe FetchContactListTotals do
  let!(:contact_list) { create :contact_list, site: site }
  let!(:site) { create :site }
  let(:service) { FetchContactListTotals.new(site) }

  describe '#call' do
    let(:contacts_count) { 10 }

    let!(:request) do
      body = {
        'Responses' => {
          'edge_contacts' => [
            { 'lid' => { 'N': contact_list.id }, 't' => { 'N': contacts_count } }
          ]
        }
      }

      stub_request(:post, 'https://dynamodb.us-east-1.amazonaws.com/')
        .with(
          body: /"RequestItems":{"edge_contacts"/,
          headers: { 'X-Amz-Target' => 'DynamoDB_20120810.BatchGetItem' }
        ).and_return(body: body.to_json)
    end

    it 'sends query to DynamoDB' do
      service.call
      expect(request).to have_been_made
    end

    it 'returns Hash[id: number]' do
      expect(service.call).to match(contact_list.id => contacts_count)
    end

    context 'when Aws::DynamoDB::Errors::ServiceError is raised' do
      before do
        allow_any_instance_of(Aws::DynamoDB::Client)
          .to receive(:batch_get_item).and_raise(Aws::DynamoDB::Errors::ServiceError.new(double('context'), 'message'))
        allow(Rails.env).to receive(:test?).and_return false
      end

      it 'sends error to Raven' do
        expect(Raven)
          .to receive(:capture_exception)
          .with(
            an_instance_of(Aws::DynamoDB::Errors::ServiceError),
            context: { request: [:batch_get_item, instance_of(Hash)] }
          )

        service.call
      end

      it 'returns {}' do
        expect(service.call).to eql({})
      end
    end
  end
end
