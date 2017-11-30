class FetchContacts::All < FetchContacts::Base
  private

  def fetch_all?
    true
  end

  def build_request
    {
      table_name: table_name,
      key_condition_expression: 'lid = :lidValue',
      expression_attribute_values: { ':lidValue' => contact_list.id },
      expression_attribute_names: { '#s' => 'status', '#e' => 'error' },
      projection_expression: 'email,n,ts,#s,#e'
    }
  end
end
