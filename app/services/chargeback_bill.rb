class ChargebackBill
  def initialize(bill)
    @bill = bill
  end

  def call
    Bill.transaction do
      create_chargeback_record!
      cancel_subscription
    end
  end

  private

  attr_reader :bill

  delegate :subscription, to: :bill

  def create_chargeback_record!
    Bill::Chargeback.create!(
      subscription_id: bill.subscription_id,
      amount: -bill.amount,
      description: 'Chargeback',
      bill_at: Time.current,
      start_date: Time.current,
      end_date: bill.end_date,
      chargedback_bill: bill,
      status: Bill::CHARGEDBACK
    )
  end

  def cancel_subscription
    return unless bill.subscription
    bill.subscription.bills.pending.each(&:voided!)

    return unless bill.site&.current_subscription

    ChangeSubscription.new(bill.site, subscription: 'free').call
  end
end
