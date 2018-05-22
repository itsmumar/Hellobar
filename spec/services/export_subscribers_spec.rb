describe ExportSubscribers, :freeze do
  let(:contact_list) { create :contact_list }
  let(:service) { described_class.new(contact_list) }
  let(:dynamo_db) { instance_double(DynamoDB) }
  let(:table_name) { 'contacts' }
  let(:subscribers) do
    [
      { 'lid' => contact_list.id, 'email' => 'email1@example.com', 'n' => 'name1', 'ts' => Time.current.to_i },
      { 'lid' => contact_list.id, 'email' => 'email2@example.com', 'n' => 'name2', 'ts' => Time.current.to_i },
      { 'lid' => contact_list.id, 'email' => 'email3@example.com', 'n' => 'name3', 'ts' => Time.current.to_i }
    ]
  end

  describe '#call' do
    before do
      allow(DynamoDB).to receive(:contacts_table_name).and_return(table_name)
      allow(DynamoDB).to receive(:new).with(cache_context: contact_list.cache_key).and_return(dynamo_db)
      allow(dynamo_db).to receive(:query_each)
        .and_yield(subscribers[0])
        .and_yield(subscribers[1])
        .and_yield(subscribers[2])
    end

    let(:request) do
      {
        table_name: table_name,
        key_condition_expression: 'lid = :lidValue',
        expression_attribute_values: { ':lidValue' => contact_list.id },
        expression_attribute_names: { '#s' => 'status', '#e' => 'error' },
        projection_expression: 'email,n,ts,lid,#s,#e',
        return_consumed_capacity: 'TOTAL'
      }
    end

    let(:csv) do
      <<~CSV
        Email,Fields,Subscribed At
        email1@example.com,name1,#{ Time.current }
        email2@example.com,name2,#{ Time.current }
        email3@example.com,name3,#{ Time.current }
      CSV
    end

    it 'fetches data from Dynamo DB' do
      expect(dynamo_db).to receive(:query_each).with(request)
      service.call
    end

    it 'returns subscribers as csv' do
      expect(service.call).to eql csv
    end
  end
end
