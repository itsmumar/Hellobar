class FetchCampaignStatistics
  TTL = 55.seconds # frontend refreshes every 60s

  def initialize(campaign)
    @campaign = campaign
  end

  def call
    initial_statistics.merge(normalize(fetch.first))
  end

  private

  attr_reader :campaign

  def normalize(statistics)
    return {} if statistics.blank?

    statistics.each_with_object({}) do |(key, value), result|
      result[key] = value.to_i unless key == 'type'
      result[key] = value if key == 'type'
    end
  end

  def build_request
    {
      table_name: table_name,
      key_condition_expression: 'id = :id',
      expression_attribute_values: { ':id' => campaign.id }
    }
  end

  def fetch
    dynamo_db.query(build_request)
  end

  def table_name
    DynamoDB.email_statictics_table_name
  end

  def dynamo_db
    DynamoDB.new expires_in: TTL
  end

  def initial_statistics
    {
      'rejected' => 0,
      'sent' => 0,
      'processed' => 0,
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
end
