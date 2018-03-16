describe FetchCampaignStatistics do
  subject { described_class.new(campaign) }
  let(:campaign) { create :campaign }
  let(:recipients_count) { 3 }

  describe '#call' do
    let(:dynamodb_request) do
      {
        table_name: 'test_email_statistics',
        key_condition_expression: 'id = :id',
        expression_attribute_values: { ':id' => campaign.id }
      }
    end

    let(:dynamodb_records) do
      [
        {
          'opened' => BigDecimal(1),
          'rejected' => BigDecimal(1),
          'delivered' => BigDecimal(1),
          'sent' => BigDecimal(1),
          'id' => BigDecimal(1),
          'type' => 'campaigns'
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
        'id' => 1,
        'type' => 'campaigns'
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
        .with(expires_in: FetchCampaignStatistics::TTL)
        .and_return(dynamodb_client)
    end

    context 'with a new campaign' do
      before do
        expect(FetchContactListTotals).to receive_service_call
          .with(campaign.site, id: campaign.contact_list_id)
          .and_return recipients_count
      end

      it 'fetches data from DynamoDB' do
        expect(dynamodb_client).to receive(:query).with(dynamodb_request)

        subject.call
      end

      it 'returns transformed DynamoDB data' do
        expect(subject.call).to eq initial_statistics.merge(expected_result)
      end
    end
  end
end
