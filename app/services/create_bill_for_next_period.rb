class CreateBillForNextPeriod
  def initialize(bill)
    @bill = bill
  end

  def call
    return if bill.subscription&.free?

    create_bill_for_next_period
  end

  private

  attr_reader :bill

  def create_bill_for_next_period
    Bill::Recurring.create!(
      subscription: bill.subscription,
      amount: bill.subscription.amount,
      description: "#{ bill.subscription.monthly? ? 'Monthly' : 'Yearly' } Renewal",
      grace_period_allowed: true,
      bill_at: 3.days.until(bill.end_date),
      start_date: bill.end_date,
      end_date: bill.end_date + bill.subscription.period
    )
  end
end
