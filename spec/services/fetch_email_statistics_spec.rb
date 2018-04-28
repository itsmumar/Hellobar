describe FetchEmailStatistics do
  subject { described_class.new(campaign) }
  let(:campaign) { create :campaign }
  let(:recipients_count) { 3 }

  describe '#call' do
    let(:dynamodb_request) do
      {
        table_name: 'test_email_statistics',
        key_condition_expression: 'id = :id AND #t = :type',
        expression_attribute_values: { ':id' => campaign.id, ':type' => 'campaign' },
        expression_attribute_names: { '#t' => 'type' }
      }
    end

    let(:dynamodb_records) do
      [
        {
          'opened' => BigDecimal(1),
          'rejected' => BigDecimal(1),
          'delivered' => BigDecimal(1),
          'submitted' => BigDecimal(1),
          'id' => BigDecimal(campaign.id),
          'type' => 'campaign'
        }
      ]
    end

    let(:expected_result) do
      {
        'subscribers' => recipients_count,
        'recipients' => 0,
        'opened' => 1,
        'rejected' => 1,
        'delivered' => 1,
        'submitted' => 1,
        'id' => campaign.id,
        'type' => 'campaign'
      }
    end

    let(:initial_statistics) do
      {
        'recipients' => 0,
        'rejected' => 0,
        'submitted' => 0,
        'deferred' => 0,
        'dropped' => 0,
        'delivered' => 0,
        'bounced' => 0,
        'opened' => 0,
        'clicked' => 0,
        'unsubscribed' => 0,
        'reported' => 0,
        'group_unsubscribed' => 0,
        'group_resubscribed' => 0
      }
    end

    let(:dynamodb_client) { instance_double(DynamoDB, query: dynamodb_records) }

    before do
      allow(DynamoDB).to receive(:new)
        .with(expires_in: FetchEmailStatistics::TTL)
        .and_return(dynamodb_client)
    end

    context 'with a new campaign' do
      before do
        expect(FetchSiteContactListTotals).to receive_service_call
          .with(campaign.site, [campaign.contact_list_id])
          .and_return(campaign.contact_list_id => recipients_count)
      end

      it 'fetches campaign statistics from DynamoDB' do
        expect(dynamodb_client).to receive(:query).with(dynamodb_request)

        subject.call
      end

      it 'returns transformed DynamoDB data' do
        expect(subject.call).to eq initial_statistics.merge(expected_result)
      end
    end

    context 'when called with sequence step instance' do
      subject { described_class.new(sequence_step) }
      let(:sequence_step) { create :sequence_step }

      let(:dynamodb_request) do
        {
          table_name: 'test_email_statistics',
          key_condition_expression: 'id = :id AND #t = :type',
          expression_attribute_values: { ':id' => sequence_step.id, ':type' => 'sequence_step' },
          expression_attribute_names: { '#t' => 'type' }
        }
      end

      let(:dynamodb_records) do
        [
          {
            'opened' => BigDecimal(2),
            'rejected' => BigDecimal(1),
            'delivered' => BigDecimal(4),
            'submitted' => BigDecimal(5),
            'id' => BigDecimal(sequence_step.id),
            'type' => 'sequence_step'
          }
        ]
      end

      let(:expected_result) do
        {
          'subscribers' => recipients_count,
          'recipients' => 0,
          'opened' => 2,
          'rejected' => 1,
          'delivered' => 4,
          'submitted' => 5,
          'id' => sequence_step.id,
          'type' => 'sequence_step'
        }
      end

      before do
        expect(FetchSiteContactListTotals).to receive_service_call
          .with(sequence_step.site, [sequence_step.contact_list_id])
          .and_return(sequence_step.contact_list_id => recipients_count)
      end

      it 'fetches sequence_step statistics from DynamoDB' do
        expect(dynamodb_client).to receive(:query).with(dynamodb_request)

        subject.call
      end

      it 'returns transformed DynamoDB data' do
        expect(subject.call).to eq initial_statistics.merge(expected_result)
      end
    end
  end
end
