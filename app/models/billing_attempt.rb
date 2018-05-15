class BillingAttempt < ApplicationRecord
  SUCCESSFUL = 'successful'.freeze
  STATE_FAILED = 'failed'.freeze
  STATE_PENDING = 'pending'.freeze
  STATUSES = [STATE_FAILED, SUCCESSFUL, STATE_PENDING].freeze

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

  ACTIONS.each do |action|
    # define .charge, .refund and .chargeback scopes
    scope action, -> { where(action: action) }

    # define #charge?, #refund?, #chargeback?
    define_method("#{ action }?") do
      self.action == action
    end
  end

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :action, presence: true, inclusion: { in: ACTIONS }

  def readonly?
    new_record? ? false : true
  end
end
