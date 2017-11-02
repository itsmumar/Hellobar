class BillingAttempt < ApplicationRecord
  SUCCESSFUL = 'successful'.freeze
  FAILED = 'failed'.freeze
  PENDING = 'pending'.freeze
  STATUSES = [FAILED, SUCCESSFUL, PENDING].freeze

  # rubocop: disable Rails/HasManyOrHasOneDependent
  belongs_to :bill
  belongs_to :credit_card
  has_one :subscription, through: :bill
  has_one :site, through: :bill
  has_many :refunds, foreign_key: 'refunded_billing_attempt_id', class_name: 'Bill::Refund'

  # define .successful, .failed and .pending scopes
  STATUSES.each do |status|
    scope status, -> { where(status: status) }
  end

  validates :status, presence: true, inclusion: { in: STATUSES }

  def readonly?
    new_record? ? false : true
  end
end
