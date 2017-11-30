class FetchContacts::Latest < FetchContacts::Base
  def initialize(contact_list, limit: 100)
    super(contact_list)

    @limit = limit
  end

  private

  attr_reader :limit

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
end
