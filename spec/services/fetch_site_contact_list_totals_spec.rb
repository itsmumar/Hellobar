describe FetchSiteContactListTotals do
  subject(:service) { described_class.new(site) }

  let!(:contact_lists) { create_list(:contact_list, 3, site: site) }
  let!(:site) { create :site }

  describe '#call' do
    let(:dynamo_db) { instance_double(DynamoDB, batch_get_item: response) }

    let(:request) do
      {
        request_items: {
          DynamoDB.contacts_table_name => {
            keys: [
              { 'lid' => contact_lists[0].id, 'email' => 'total' },
              { 'lid' => contact_lists[1].id, 'email' => 'total' },
              { 'lid' => contact_lists[2].id, 'email' => 'total' }
            ],
            projection_expression: 'lid,t'
          }
        },
        return_consumed_capacity: 'TOTAL'
      }
    end

    let(:response) do
      [
        { 'lid' => contact_lists[0].id, 't' => 3 },
        { 'lid' => contact_lists[1].id, 't' => 1 },
        { 'lid' => contact_lists[2].id, 't' => 2 }
      ]
    end

    let(:expected_result) do
      {
        contact_lists[0].id => 3,
        contact_lists[1].id => 1,
        contact_lists[2].id => 2
      }
    end

    before do
      allow(DynamoDB).to receive(:new).and_return(dynamo_db)
      allow(dynamo_db).to receive_message_chain(:batch_get_item, :fetch).and_return(response)
    end

    it 'sends query to DynamoDB' do
      expect(dynamo_db).to receive_message_chain(:batch_get_item).with(hash_including(request))
      service.call
    end

    it 'returns Hash[id: number]' do
      expect(service.call).to match(expected_result)
    end

    context 'when particular contact_list_id is given' do
      subject(:service) { described_class.new(site, [contact_list_id]) }

      let(:contact_list_id) { 12 }

      let(:request) do
        {
          request_items: {
            DynamoDB.contacts_table_name => {
              keys: [
                { 'lid' => contact_list_id, 'email' => 'total' }
              ],
              projection_expression: 'lid,t'
            }
          },
          return_consumed_capacity: 'TOTAL'
        }
      end

      it 'request totals only for given list' do
        expect(dynamo_db).to receive_message_chain(:batch_get_item).with(request)
        service.call
      end
    end

    context 'when nil or string contact list ID is given' do
      subject(:service) { described_class.new(site, [7, '21', nil, 15]) }

      let(:request) do
        {
          request_items: {
            DynamoDB.contacts_table_name => {
              keys: [
                { 'lid' => 7, 'email' => 'total' },
                { 'lid' => 21, 'email' => 'total' },
                { 'lid' => 15, 'email' => 'total' }
              ],
              projection_expression: 'lid,t'
            }
          },
          return_consumed_capacity: 'TOTAL'
        }
      end

      it 'converts strings to integer and skips nils' do
        expect(dynamo_db).to receive_message_chain(:batch_get_item).with(request)
        service.call
      end
    end
  end
end
