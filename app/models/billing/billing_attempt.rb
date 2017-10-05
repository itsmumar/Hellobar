class BillingAttempt < ActiveRecord::Base
  # rubocop: disable Rails/HasManyOrHasOneDependent
  belongs_to :bill
  belongs_to :credit_card
  has_one :subscription, through: :bill
  has_one :site, through: :bill
  has_many :refunds, foreign_key: 'refunded_billing_attempt_id', class_name: 'Bill::Refund'

  scope :successful, -> { where(status: 'successful') }
  scope :failed, -> { where(status: 'failed') }

  def readonly?
    new_record? ? false : true
  end

  def status
    super.to_sym
  end
end
