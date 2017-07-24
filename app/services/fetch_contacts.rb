class FetchContacts
  MAXIMUM_ALLOWED_LIMIT = 100

  def initialize(contact_list, limit: MAXIMUM_ALLOWED_LIMIT)
    @contact_list = contact_list
    @limit = limit
  end

  def call
    process_response
  end

  private

  attr_reader :contact_list

  def process_response
    response.map do |item|
      {
        email: item['email'],
        name: item['n'],
        subscribed_at: item['ts'].presence && Time.zone.at(item['ts'].to_i)
      }
    end
  end

  def response
    dynamo_db.fetch request
  end

  def request
    {
      table_name: table,
      index_name: 'ts-index', # use secondary index
      key_condition_expression: 'lid = :lidValue',
      expression_attribute_values: { ':lidValue' => contact_list.id },
      projection_expression: 'email,n,ts',
      limit: limit,
      scan_index_forward: false # sort results in reverse chronological order
    }
  end

  def cache_key
    contact_list.cache_key
  end

  def limit
    @limit > MAXIMUM_ALLOWED_LIMIT ? MAXIMUM_ALLOWED_LIMIT : @limit
  end

  def table
    Rails.env.production? ? 'contacts' : 'edge_contacts'
  end

  def dynamo_db
    DynamoDB.new(cache_key: cache_key)
  end
end
