class UpdateContactStatus
  def initialize contact_list_id, email, status, error: nil
    @contact_list_id = contact_list_id
    @email = email
    @status = status
    @error = error
  end

  def call
    update_status
  end

  private

  attr_reader :contact_list_id, :email, :status, :error

  def update_status
    dynamo_db.update_item(
      key: key,
      attribute_updates: attribute_updates,
      return_values: 'NONE',
      return_consumed_capacity: 'TOTAL',
      table_name: table_name
    )
  end

  def key
    {
      lid: contact_list_id,
      email: email
    }
  end

  def attribute_updates
    error ? erroroneous_attribute_updates : successful_attribute_updates
  end

  def successful_attribute_updates
    {
      status: {
        value: status,
        action: 'PUT'
      }
    }
  end

  def erroroneous_attribute_updates
    successful_attribute_updates.merge(
      error: {
        value: error,
        action: 'PUT'
      }
    )
  end

  def table_name
    DynamoDB.contacts_table_name
  end

  def dynamo_db
    DynamoDB.new
  end
end
