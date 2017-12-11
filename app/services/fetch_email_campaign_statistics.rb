class FetchEmailCampaignStatistics
  def initialize(email_campaign)
    @email_campaign = email_campaign
  end

  def call
    initial_statistics.merge(normalize(fetch.first))
  end

  private

  attr_reader :email_campaign

  def normalize(statistics)
    return {} unless statistics.present?

    statistics.each_with_object({}) do |(key, value), result|
      result[key] = value.to_i unless key == 'type'
      result[key] = value if key == 'type'
    end
  end

  def build_request
    {
      table_name: table_name,
      key_condition_expression: 'id = :id',
      expression_attribute_values: { ':id' => email_campaign.id }
    }
  end

  def fetch
    dynamo_db.query(build_request)
  end

  def table_name
    DynamoDB.email_statictics_table_name
  end

  def dynamo_db
    DynamoDB.new
  end

  def initial_statistics
    {
      'sent' => 0,
      'processed' => 0,
      'deferred' => 0,
      'delivered' => 0,
      'opened' => 0,
      'clicked' => 0,
      'bounced' => 0,
      'dropped' => 0,
      'reported' => 0,
      'unsubscribed' => 0,
      'group_unsubscribed' => 0,
      'group_resubscribed' => 0
    }
  end
end
