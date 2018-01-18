class Whitelabel < ApplicationRecord
  NEW = 'new'.freeze
  VALID = 'valid'.freeze
  STATUSES = [NEW, VALID].freeze

  DOMAIN_REGEXP = /.+\..+/
  SUBDOMAIN_REGEXP = /.+\..+\..+/

  belongs_to :site

  validates :domain, presence: true, format: { with: DOMAIN_REGEXP }
  validates :subdomain, presence: true, format: { with: SUBDOMAIN_REGEXP }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :site, presence: true

  validate :subdomain_correctness
  validate :domain_correctness

  private

  def subdomain_correctness
    # triggers host validation
    Addressable::URI.new(host: subdomain)
  rescue Addressable::URI::InvalidURIError
    errors.add :subdomain, 'Invalid characters used'
  end

  def domain_correctness
    return if subdomain.to_s.include? domain.to_s

    errors.add :domain, 'Must be the same host/name as used in the subdomain'
  end
end
