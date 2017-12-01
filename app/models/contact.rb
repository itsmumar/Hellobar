class Contact
  attr_accessor :lid, :email, :name, :subscribed_at, :status, :error

  def initialize(attributes)
    attributes.each do |key, value|
      send("#{ key }=", value)
    end
  end

  def self.from_dynamo_db(record)
    new(lid: record['lid'],
        email: record['email'],
        name: record['n'],
        subscribed_at: record['ts'].present? && Time.zone.at(record['ts'].to_i),
        status: record['status'],
        error: record['error'])
  end

  def ==(other)
    other.class == self.class && other.lid == lid && other.email == email
  end
end
