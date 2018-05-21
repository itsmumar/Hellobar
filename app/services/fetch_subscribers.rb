# Example:
#
#   contact_list = OpenStruct.new(id: 24, cache_key: 24)
#   last_page = FetchSubscribers.new(contact_list).call #=> { items: [...], first_page: {}, ... }
#   last_page_1 = FetchSubscribers.new(contact_list, last_page[:next_page]).call
#   last_page_2 = FetchSubscribers.new(contact_list, last_page_1[:next_page]).call
#   last_page_1x = FetchSubscribers.new(contact_list, last_page_2[:previous_page]).call
#   last_page_1[:items] == last_page_1x[:items] #=> true
#
class FetchSubscribers
  PAGE_SIZE = 100
  INDEX_NAME = 'ts-index'.freeze

  def initialize(contact_list, key: nil, forward: false)
    @contact_list = contact_list
    @key = key&.symbolize_keys
    @forward = forward
  end

  def call
    @response = dynamo_db.raw_query(build_request)

    {
      items: build_contacts(forward ? response.items.reverse : response.items),
      first_page: first_page_params,
      last_page: last_page_params,
      next_page: next_page_params,
      previous_page: previous_page_params
    }
  end

  private

  attr_reader :contact_list, :key, :forward, :response

  def backward
    !forward
  end

  def build_request
    query = {
      table_name: table_name,
      index_name: INDEX_NAME,
      key_condition_expression: 'lid = :lidValue',
      expression_attribute_values: { ':lidValue' => contact_list.id },
      expression_attribute_names: { '#s' => 'status', '#e' => 'error' },
      projection_expression: 'email,n,ts,lid,#s,#e',
      limit: PAGE_SIZE,
      return_consumed_capacity: 'TOTAL',
      scan_index_forward: forward
    }
    query[:exclusive_start_key] = parse_key(key) if key.present?
    query
  end

  def first_page_params
    return if first_page?

    {
      forward: false
    }
  end

  def last_page_params
    return if last_page?

    {
      forward: true
    }
  end

  def next_page_params
    return if last_page? || response.items.blank?

    first_item = forward ? response.items.first : response.items.last

    {
      key: serialize_key(first_item),
      forward: false
    }
  end

  def previous_page_params
    return if first_page? || response.items.blank?

    last_item = forward ? response.items.last : response.items.first

    {
      key: serialize_key(last_item),
      forward: true
    }
  end

  def last_page?
    (forward && !key) || (backward && !response.last_evaluated_key)
  end

  def first_page?
    (backward && !key) || (forward && !response.last_evaluated_key)
  end

  def table_name
    DynamoDB.contacts_table_name
  end

  def dynamo_db
    DynamoDB.new(cache_context: contact_list.cache_key)
  end

  def serialize_key(item)
    {
      email: item['email'],
      lid: item['lid'].to_i,
      ts: item['ts'].to_i
    }
  end

  def parse_key(key)
    {
      email: key[:email],
      lid: key[:lid].to_i,
      ts: key[:ts].to_i
    }
  end

  def build_contacts(items)
    items.map do |item|
      Contact.from_dynamo_db(item)
    end
  end
end
