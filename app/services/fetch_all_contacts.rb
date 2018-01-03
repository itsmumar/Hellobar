class FetchAllContacts
  def initialize(contact_list)
    @contact_list = contact_list
  end

  def call
    remove_total_record(contacts)
  end

  private

  attr_reader :contact_list

  def contacts
    fetch.map do |record|
      Contact.from_dynamo_db(record)
    end
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

  def fetch
    dynamo_db.query_enum(build_request)
  end

  def remove_total_record(contacts)
    contacts.reject { |contact| contact.email == 'total' }
  end

  def table_name
    DynamoDB.contacts_table_name
  end

  def dynamo_db
    DynamoDB.new
  end
end
