class Whitelabel < ApplicationRecord
  NEW = 'new'.freeze
  VALID = 'valid'.freeze
  STATUSES = [NEW, VALID].freeze

  NAME_REGEXP = /.+\..+/

  belongs_to :site

  validates :domain, presence: true, format: { with: NAME_REGEXP }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :site, presence: true

  validate :name_correctness

  private

  def name_correctness
    # triggers host validation
    Addressable::URI.new(host: domain)
  rescue Addressable::URI::InvalidURIError
    errors.add :domain, 'Invalid characters in the domain name'
  end
end
