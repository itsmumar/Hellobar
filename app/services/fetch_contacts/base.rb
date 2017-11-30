class FetchContacts::Base
  def initialize(contact_list)
    @contact_list = contact_list
  end

  def call
    fetch.map do |record|
      process(record)
    end
  end

  private

  attr_reader :contact_list

  def fetch_all?
    false
  end

  def build_request
    raise NotImplemented
  end

  def fetch
    dynamo_db.query(build_request, fetch_all: fetch_all?)
  end

  def process(record)
    {
      email: record['email'],
      name: record['n'],
      subscribed_at: record['ts'].presence && Time.zone.at(record['ts'].to_i),
      status: record['status'],
      error: record['error']
    }
  end

  def table_name
    DynamoDB.contacts_table_name
  end

  def dynamo_db
    DynamoDB.new
  end
end
