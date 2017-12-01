describe FetchAllContacts do
  subject { described_class.new(contact_list) }
  let(:contact_list) { create :contact_list }

  describe '#call', freeze: true do
    let(:dynamodb_request) do
      {
        table_name: 'development_contacts',
        key_condition_expression: 'lid = :lidValue',
        expression_attribute_values: { ':lidValue' => contact_list.id },
        expression_attribute_names: { '#s' => 'status', '#e' => 'error' },
        projection_expression: 'email,n,ts,#s,#e'
      }
    end

    let(:dynamodb_records) do
      [
        {
          'email' => 'j.black@gmail.com',
          'n' => 'John Black',
          'ts' => 1512077546,
          'status' => '',
          'error' => ''
        },
        {
          'email' => 'abc123@gmail.com',
          'n' => '',
          'ts' => 1512077321,
          'status' => 'error',
          'error' => 'Email is blacklisted'
        }
      ]
    end

    let(:expected_result) do
      [
        Contact.new(email: 'j.black@gmail.com',
                    name: 'John Black',
                    subscribed_at: Time.zone.at(1512077546),
                    status: '',
                    error: ''),
        Contact.new(email: 'abc123@gmail.com',
                    name: '',
                    subscribed_at: Time.zone.at(1512077321),
                    status: 'error',
                    error: 'Email is blacklisted')
      ]
    end

    let(:dynamodb_client) { instance_double(DynamoDB, query_enum: dynamodb_records.to_enum(:each)) }

    before do
      allow(DynamoDB).to receive(:new).and_return(dynamodb_client)
    end

    it 'fetches data from DynamoDB' do
      expect(dynamodb_client).to receive(:query_enum).with(dynamodb_request)

      subject.call
    end

    it 'returns transformed DynamoDB data' do
      expect(subject.call).to eq(expected_result)
    end
  end
end
