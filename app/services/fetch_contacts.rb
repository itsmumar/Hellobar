class FetchContacts
  def initialize(contact_list, limit: 20)
    @contact_list = contact_list
    @limit = limit
  end

  def call
    process DynamoDB.new(cache_key: cache_key, expires_in: 1.hour).fetch(request)
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
    "#{ contact_list.cache_key }/#{ limit }"
  end

  def request
    {
      table_name: table,
      key_condition_expression: 'lid = :lidValue',
      expression_attribute_values: { ':lidValue' => contact_list.id },
      projection_expression: 'email,n,ts',
      limit: limit
    }
  end

  def table
    Rails.env.production? ? 'contacts' : 'edge_contacts'
  end
end
