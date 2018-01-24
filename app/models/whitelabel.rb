class Whitelabel < ApplicationRecord
  NEW = 'new'.freeze
  VALID = 'valid'.freeze
  INVALID = 'invalid'.freeze
  STATUSES = [NEW, VALID, INVALID].freeze

  DOMAIN_REGEXP = /.+\..+/

  belongs_to :site

  validates :domain, presence: true, format: { with: DOMAIN_REGEXP }
  validates :subdomain, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :site, presence: true

  validate :domain_correctness

  attr_accessor :dns

  def valid!
    update! status: VALID
  end

  def invalid!
    update! status: INVALID
  end

  private

  def domain_correctness
    # triggers host validation
    Addressable::URI.new(host: domain)
  rescue Addressable::URI::InvalidURIError
    errors.add :domain, 'Name contains invalid characters'
  end
end
