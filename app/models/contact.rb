class Contact
  SYNCED = 'synced'
  UNSYCHED = 'unsynced'
  ERROR = 'error'

  STATUSES = [SYNCED, UNSYCHED, ERROR]

  include ActiveModel::Model

  attr_accessor :lid, :email, :name, :subscribed_at, :status, :error

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

  def unsynched?
    status.blank? || status == UNSYCHED
  end

  def synched?
    status == SYNCED
  end

  def error?
    status == ERROR
  end
end
