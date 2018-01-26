class DeleteContact
  def initialize contact_list, email
    @contact_list = contact_list
    @email = email
  end

  def call
    delete
    update_totals
    update_contact_list_cache
  end

  private

  attr_reader :contact_list, :email, :name, :old_record

  def update_contact_list_cache
    contact_list.touch
  end

  def delete
    response = dynamo_db.delete_item({
      key: key,
      return_values: 'ALL_OLD',
      table_name: table_name
    })
    @old_record = response.attributes
  end

  def update_totals
    return unless deleted?

    dynamo_db.update_item(
      key: totals_key,
      attribute_updates: {
        t: {
          value: -1,
          action: 'ADD'
        }
      },
      return_values: 'NONE',
      return_consumed_capacity: 'TOTAL',
      table_name: table_name
    )
  end

  def deleted?
    old_record.present?
  end

  def totals_key
    {
      lid: contact_list.id,
      email: 'total'
    }
  end

  def key
    @attributes ||= {
      lid: contact_list.id,
      email: email
    }
  end

  def table_name
    DynamoDB.contacts_table_name
  end

  def dynamo_db
    DynamoDB.new
  end
end
