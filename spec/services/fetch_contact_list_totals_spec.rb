describe FetchContactListTotals do
  let!(:contact_list) { create :contact_list, site: site }
  let!(:site) { create :site }
  let(:service) { FetchContactListTotals.new(site) }

  describe '#call' do
    let(:contacts_count) { 10 }

    let!(:request) do
      body = {
        'Responses' => {
          'test_contacts' => [
            { 'lid' => { 'N': contact_list.id }, 't' => { 'N': contacts_count } }
          ]
        }
      }

      stub_request(:post, 'https://dynamodb.us-east-1.amazonaws.com/')
        .with(
          body: /"RequestItems":{"test_contacts"/,
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
  end
end
