class BillingAttempt < ApplicationRecord
  SUCCESSFUL = 'successful'.freeze
  FAILED = 'failed'.freeze
  PENDING = 'pending'.freeze
  STATUSES = [FAILED, SUCCESSFUL, PENDING].freeze

  CHARGE = 'charge'.freeze
  REFUND = 'refund'.freeze
  CHARGEBACK = 'chargeback'.freeze
  ACTIONS = [CHARGE, REFUND, CHARGEBACK].freeze

  belongs_to :bill
  belongs_to :credit_card
  has_one :subscription, through: :bill
  has_one :site, through: :bill

  STATUSES.each do |status|
    # define .successful, .failed and .pending scopes
    scope status, -> { where(status: status) }

    # define #successful?, #failed?, #pending?
    define_method status + '?' do
      self.status == status
    end
  end

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :action, presence: true, inclusion: { in: ACTIONS }

  def readonly?
    new_record? ? false : true
  end
end
