class Contact
  SYNCED = 'synced'.freeze
  UNSYNCED = 'unsynced'.freeze
  ERROR = 'error'.freeze

  STATUSES = [SYNCED, UNSYNCED, ERROR].freeze

  include ActiveModel::Model

  attr_accessor :lid, :email, :name, :subscribed_at, :status, :error

  def self.from_dynamo_db(record)
    new(lid: record['lid'].to_i,
        email: record['email'],
        name: record['n'],
        subscribed_at: record['ts'].present? && Time.zone.at(record['ts'].to_i),
        status: record['status'],
        error: record['error'])
  end

  def ==(other)
    other.class == self.class && other.lid == lid && other.email == email
  end

  def unsynced?
    status.blank? || status == UNSYNCED
  end

  def synced?
    status == SYNCED
  end

  def error?
    status == ERROR
  end
end
