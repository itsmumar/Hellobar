class ExportSubscribers
  TOTAL_COUNTER = 'total'.freeze

  def initialize(contact_list)
    @contact_list = contact_list
  end

  def call
    CSV.generate do |csv|
      csv << %w[Email Fields Subscribed\ At]

      fetch_subscribers do |item|
        subscriber = Contact.from_dynamo_db(item)

        next if subscriber.email == TOTAL_COUNTER

        csv << [subscriber.email, subscriber.name, subscriber.subscribed_at.to_s]
      end
    end
  end

  private

  attr_reader :contact_list

  def table_name
    DynamoDB.contacts_table_name
  end

  def dynamo_db
    DynamoDB.new(cache_context: contact_list.cache_key)
  end

  def request
    {
      table_name: table_name,
      key_condition_expression: 'lid = :lidValue',
      expression_attribute_values: { ':lidValue' => contact_list.id },
      expression_attribute_names: { '#s' => 'status', '#e' => 'error' },
      projection_expression: 'email,n,ts,lid,#s,#e',
      return_consumed_capacity: 'TOTAL'
    }
  end

  def fetch_subscribers(&block)
    dynamo_db.query_each(request, &block)
  end
end
