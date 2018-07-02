class ChargebackBill
  def initialize(bill)
    @bill = bill
  end

  def call
    Bill.transaction do
      transition_bill_status
      create_billing_attempt(bill)
      cancel_subscription
    end
  end

  private

  attr_reader :bill

  delegate :subscription, to: :bill

  def transition_bill_status
    bill.chargeback!
  end

  def create_billing_attempt(bill)
    bill.billing_attempts.create!(
      status: BillingAttempt::SUCCESSFUL,
      action: BillingAttempt::CHARGEBACK
    )
  end

  def cancel_subscription
    return unless bill.subscription
    bill.subscription.bills.pending.each(&:void!)

    return unless bill.site&.current_subscription

    ChangeSubscription.new(bill.site, subscription: 'free').call
  end
end
