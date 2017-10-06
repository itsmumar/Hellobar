class FetchContacts
  def initialize(contact_list, limit: 100)
    @contact_list = contact_list
    @limit = limit
  end

  def call
    process_response
  end

  private

  attr_reader :contact_list, :limit

  def process_response
    response.map do |item|
      {
        email: item['email'],
        name: item['n'],
        subscribed_at: item['ts'].presence && Time.zone.at(item['ts'].to_i),
        status: item['status'],
        error: item['error']
      }
    end
  end

  def response
    dynamo_db.query request
  end

  def request
    {
      table_name: table_name,
      index_name: 'ts-index', # use secondary index
      key_condition_expression: 'lid = :lidValue',
      expression_attribute_values: { ':lidValue' => contact_list.id },
      expression_attribute_names: { '#s' => 'status', '#e' => 'error' },
      projection_expression: 'email,n,ts,#s,#e',
      limit: limit,
      scan_index_forward: false # sort results in reverse chronological order
    }
  end

  def cache_key
    if limit
      "#{ contact_list.cache_key }/#{ limit }"
    else
      "#{ contact_list.cache_key }/all"
    end
  end

  def table_name
    DynamoDB.contacts_table_name
  end

  def dynamo_db
    DynamoDB.new(cache_key: cache_key)
  end
end
