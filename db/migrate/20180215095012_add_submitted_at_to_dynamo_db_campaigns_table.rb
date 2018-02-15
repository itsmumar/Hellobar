class AddSubmittedAtToDynamoDbCampaignsTable < ActiveRecord::Migration
  TABLE_NAME = 'campaigns'.freeze

  def up
    i = 0
    scan_campaigns do |campaign|
      i += 1
      set_submitted_at(campaign)
      puts "#{ i } records are processed" if (i % 1000).zero?
    end

    puts "#{ i } records are processed"
  end

  def down
    # do nothing
  end

  private

  def scan_campaigns
    request = { table_name: TABLE_NAME, projection_expression: 'email,campaign_id' }

    loop do
      response = dynamo.scan(request)
      campaigns, last_evaluated_key = response.items, response.last_evaluated_key

      campaigns.each do |campaign|
        yield campaign
      end

      break unless last_evaluated_key
      request = request.merge(exclusive_start_key: last_evaluated_key)
    end
  end

  def set_submitted_at(record)
    dynamo.update_item(
      key: record,
      expression_attribute_names: {
        '#S' => 'submitted_at'
      },
      expression_attribute_values: {
        ':t' => timestamp(record).to_i
      },
      update_expression: 'SET #S = :t',
      table_name: TABLE_NAME
    )
  end

  def timestamp(record)
    campaign = fetch_campaign(record['campaign_id'])
    campaign&.sent_at || campaign&.updated_at || Time.current
  end

  def fetch_campaign(campaign_id)
    @campaigns ||= Hash.new { |h, id| h[id] = Campaign.find_by(id: id) }
    @campaigns[campaign_id]
  end

  def dynamo
    @dynamo ||= DynamoDB.new
  end
end
