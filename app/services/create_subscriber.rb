class CreateSubscriber
  def initialize(contact_list, params)
    @contact_list = contact_list
    @email = params.fetch(:email)
    @name = params.fetch(:name)
  end

  def call
    create
    update_totals
    update_contact_list_cache
    attributes
  end

  private

  attr_reader :contact_list, :email, :name, :old_record

  def update_contact_list_cache
    contact_list.touch
  end

  def create
    response = dynamo_db.put_item(
      item: attributes,
      return_consumed_capacity: 'TOTAL',
      return_values: 'ALL_OLD',
      return_item_collection_metrics: 'SIZE',
      table_name: table_name
    )

    @old_record = response.attributes
  end

  def update_totals
    return unless new_record?

    UpdateSubscribersCounter.new(contact_list.id, value: 1).call
  end

  def new_record?
    old_record.blank?
  end

  def attributes
    @attributes ||= {
      lid: contact_list.id,
      email: email,
      n: name,
      ts: Time.current.to_i
    }
  end

  def table_name
    DynamoDB.contacts_table_name
  end

  def dynamo_db
    DynamoDB.new
  end
end
