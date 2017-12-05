class FetchLatestContacts
  def initialize(contact_list, limit: 100)
    @contact_list = contact_list
    @limit = limit
  end

  def call
    fetch.map do |record|
      Contact.from_dynamo_db(record)
    end
  end

  private

  attr_reader :contact_list, :limit

  def build_request
    {
      table_name: table_name,
      index_name: 'ts-index',
      key_condition_expression: 'lid = :lidValue',
      expression_attribute_values: { ':lidValue' => contact_list.id },
      expression_attribute_names: { '#s' => 'status', '#e' => 'error' },
      projection_expression: 'email,n,ts,#s,#e',
      limit: limit,
      scan_index_forward: false # sort results in reverse chronological order
    }
  end

  def fetch
    dynamo_db.query_enum(build_request, fetch_all: false)
  end

  def table_name
    DynamoDB.contacts_table_name
  end

  def dynamo_db
    DynamoDB.new
  end
end
