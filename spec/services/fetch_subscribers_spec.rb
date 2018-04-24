describe FetchSubscribers do
  subject(:service) { described_class.new(contact_list, params) }

  let(:contact_list) { create(:contact_list) }
  let(:params) { {} }

  let(:dynamodb) { instance_double(DynamoDB, raw_query: OpenStruct.new(response)) }
  let(:request) do
    {
      table_name: 'test_contacts',
      index_name: 'ts-index',
      key_condition_expression: 'lid = :lidValue',
      expression_attribute_values: { ':lidValue' => contact_list.id },
      expression_attribute_names: { '#s' => 'status', '#e' => 'error' },
      projection_expression: 'email,n,ts,lid,#s,#e',
      limit: 100,
      scan_index_forward: false
    }
  end
  let(:response) { { items: items, last_evaluated_key: last_evaluated_key } }
  let(:items) { [] }
  let(:last_evaluated_key) { nil }

  let(:all_records) do
    [
      { 'lid' => contact_list.id, 'email' => 'john@gmail.com', 'ts' => 1.day.ago.to_i, 'n' => 'John' },
      { 'lid' => contact_list.id, 'email' => 'ben@gmail.com', 'ts' => 2.days.ago.to_i, 'n' => 'Ben' },
      { 'lid' => contact_list.id, 'email' => 'dan@gmail.com', 'ts' => 3.days.ago.to_i, 'n' => 'Dan' },
      { 'lid' => contact_list.id, 'email' => 'jacob@gmail.com', 'ts' => 4.days.ago.to_i, 'n' => 'Jacob' },
      { 'lid' => contact_list.id, 'email' => 'dylan@gmail.com', 'ts' => 5.days.ago.to_i, 'n' => 'Dylan' },
      { 'lid' => contact_list.id, 'email' => 'james@gmail.com', 'ts' => 6.days.ago.to_i, 'n' => 'James' }
    ]
  end

  let(:subscribers) do
    all_records.map do |item|
      Contact.from_dynamo_db(item)
    end
  end

  before do
    allow(DynamoDB).to receive(:new).and_return(dynamodb)
  end

  it 'sends query to Dynamo DB' do
    expect(dynamodb).to receive(:raw_query).with(request)
    subject.call
  end

  context 'when fetching backward (latest first)' do
    context 'when fetching 1st page' do
      let(:params) { { forward: false } }
      let(:items) { all_records[0..1] }
      let(:last_evaluated_key) { subscribers[1].key }

      it 'includes items' do
        expect(service.call[:items]).to eq(subscribers[0..1])
      end

      it 'includes next_page' do
        expect(service.call[:next_page]).to eq({ forward: false, key: subscribers[1].key })
      end

      it 'includes last_page' do
        expect(service.call[:last_page]).to eq({ forward: true })
      end

      it 'does not include previous_page' do
        expect(service.call[:previous_page]).to be_nil
      end

      it 'does not include first_page' do
        expect(service.call[:first_page]).to be_nil
      end

      context 'when there are no more records' do
        let(:last_evaluated_key) { nil }

        it 'does not include next_page' do
          expect(service.call[:next_page]).to be_nil
        end

        it 'does not include last_page' do
          expect(service.call[:last_page]).to be_nil
        end
      end
    end

    context 'when fetching 2nd page' do
      let(:params) { { forward: false, key: subscribers[1].key } }
      let(:items) { all_records[2..3] }
      let(:last_evaluated_key) { subscribers[3].key }

      it 'includes items' do
        expect(service.call[:items]).to eq(subscribers[2..3])
      end

      it 'includes next_page' do
        expect(service.call[:next_page]).to eq({ forward: false, key: subscribers[3].key })
      end

      it 'includes last_page' do
        expect(service.call[:last_page]).to eq({ forward: true })
      end

      it 'includes previous_page' do
        expect(service.call[:previous_page]).to eq({ forward: true, key: subscribers[2].key })
      end

      it 'includes first_page' do
        expect(service.call[:first_page]).to eq({ forward: false })
      end

      context 'when there are no more records' do
        let(:last_evaluated_key) { nil }

        it 'does not include next_page' do
          expect(service.call[:next_page]).to be_nil
        end

        it 'does not include last_page' do
          expect(service.call[:last_page]).to be_nil
        end
      end
    end
  end

  context 'when fetching forward (oldest first)' do
    context 'when fetching last page' do
      let(:params) { { forward: true } }
      let(:items) { all_records[4..5].reverse }
      let(:last_evaluated_key) { subscribers[4].key }

      it 'includes items' do
        expect(service.call[:items]).to eq(subscribers[4..5])
      end

      it 'does not include next_page' do
        expect(service.call[:next_page]).to be_nil
      end

      it 'does not include last_page' do
        expect(service.call[:last_page]).to be_nil
      end

      it 'includes previous_page' do
        expect(service.call[:previous_page]).to eq({ forward: true, key: subscribers[4].key })
      end

      it 'includes first_page' do
        expect(service.call[:first_page]).to eq({ forward: false })
      end

      context 'when there are no more records' do
        let(:last_evaluated_key) { nil }

        it 'does not include previous_page' do
          expect(service.call[:previous_page]).to be_nil
        end

        it 'does not include first_page' do
          expect(service.call[:first_page]).to be_nil
        end
      end
    end

    context 'when fetching 2nd page from the end' do
      let(:params) { { forward: true, key: subscribers[4].key } }
      let(:items) { all_records[2..3].reverse }
      let(:last_evaluated_key) { subscribers[2].key }

      it 'includes items' do
        expect(service.call[:items]).to eq(subscribers[2..3])
      end

      it 'includes next_page' do
        expect(service.call[:next_page]).to eq({ forward: false, key: subscribers[3].key })
      end

      it 'includes last_page' do
        expect(service.call[:last_page]).to eq({ forward: true })
      end

      it 'includes previous_page' do
        expect(service.call[:previous_page]).to eq({ forward: true, key: subscribers[2].key })
      end

      it 'includes first_page' do
        expect(service.call[:first_page]).to eq({ forward: false })
      end

      context 'when there are no more records' do
        let(:last_evaluated_key) { nil }

        it 'does not include previous_page' do
          expect(service.call[:previous_page]).to be_nil
        end

        it 'does not include first_page' do
          expect(service.call[:first_page]).to be_nil
        end
      end
    end
  end
end
