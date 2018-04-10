# Example:
#
#   contact_list = OpenStruct.new(id: 24, cache_key: 24)
#   last_page = FetchContacts.new(contact_list, page_size: 2).call #=> { items: [...], first_page: {}, ... }
#   last_page_1 = FetchContacts.new(contact_list, last_page[:prev_page]).call
#   last_page_2 = FetchContacts.new(contact_list, last_page_1[:prev_page]).call
#   last_page_1x = FetchContacts.new(contact_list, last_page_2[:next_page]).call
#   last_page_1[:items] == last_page_1x[:items] #=> true
#
class FetchContacts
  DEFAULT_PAGE_SIZE = 100
  INDEX_NAME = 'ts-index'.freeze
  KEY_ATTRIBUTES = %w[lid email ts].freeze

  def initialize(contact_list, key: nil, page_size: nil, forward: false)
    @contact_list = contact_list
    @key = key
    @page_size = page_size || DEFAULT_PAGE_SIZE
    @forward = forward
  end

  def call
    @response = dynamo_db.raw_query(build_request)

    {
      items: build_contacts(forward ? response.items.reverse : response.items),
      first_page: first_page_params,
      last_page: last_page_params,
      next_page: next_page_params,
      prev_page: prev_page_params
    }
  end

  private

  attr_reader :contact_list, :key, :page_size, :forward, :response

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
      limit: page_size,
      scan_index_forward: forward
    }
    query[:exclusive_start_key] = key if key.present?
    query
  end

  def first_page_params
    return if first_page?

    {
      forward: true,
      page_size: page_size
    }
  end

  def last_page_params
    return if last_page?

    {
      forward: false,
      page_size: page_size
    }
  end

  def next_page_params
    return if last_page? || response.items.blank?

    last_item = forward ? response.items.last : response.items.first

    {
      key: last_item.slice(*KEY_ATTRIBUTES),
      forward: true,
      page_size: page_size
    }
  end

  def prev_page_params
    return if first_page? || response.items.blank?

    first_item = forward ? response.items.first : response.items.last

    {
      key: first_item.slice(*KEY_ATTRIBUTES),
      forward: false,
      page_size: page_size
    }
  end

  def last_page?
    (backward && !key) || (forward && !response.last_evaluated_key)
  end

  def first_page?
    (forward && !key) || (backward && !response.last_evaluated_key)
  end

  def table_name
    DynamoDB.contacts_table_name
  end

  def dynamo_db
    DynamoDB.new(cache_context: contact_list.cache_key)
  end

  def build_contacts(items)
    items.map do |item|
      Contact.from_dynamo_db(item)
    end
  end
end
