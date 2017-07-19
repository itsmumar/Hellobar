class FetchContacts
  MAXIMUM_ALLOWED_LIMIT = 100
  CACHE_TTL = 1.hour

  def initialize(contact_list, limit: 20)
    @contact_list = contact_list
    @limit = limit
  end

  def call
    response = DynamoDB.new(cache_key: cache_key, expires_in: CACHE_TTL).fetch(request)
    process(response).take(limit)
  end

  private

  attr_reader :contact_list, :limit

  def process(response)
    response.map do |item|
      {
        email: item['email'],
        name: item['n'],
        subscribed_at: item['ts'].presence && Time.zone.at(item['ts'].to_i)
      }
    end
  end

  def cache_key
    contact_list.cache_key
  end

  def request
    {
      table_name: table,
      key_condition_expression: 'lid = :lidValue',
      filter_expression: 'attribute_not_exists(t)', # filter out "total" records
      expression_attribute_values: { ':lidValue' => contact_list.id },
      projection_expression: 'email,n,ts',
      limit: MAXIMUM_ALLOWED_LIMIT
    }
  end

  def table
    Rails.env.production? ? 'contacts' : 'edge_contacts'
  end
end
