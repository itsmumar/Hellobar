class UpdateSubscribersCounter
  def initialize(contact_list_id, value:)
    @contact_list_id = contact_list_id
    @value = value
  end

  def call
    update
  end

  private

  attr_reader :contact_list_id, :value

  def update
    dynamo_db.update_item(
      key: totals_key,
      attribute_updates: {
        t: {
          value: value,
          action: 'ADD'
        }
      },
      return_values: 'NONE',
      return_consumed_capacity: 'TOTAL',
      table_name: table_name
    )
  end

  def totals_key
    {
      lid: contact_list_id,
      email: 'total'
    }
  end

  def table_name
    DynamoDB.contacts_table_name
  end

  def dynamo_db
    DynamoDB.new
  end
end
