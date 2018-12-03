class CreateAndPayOverageBill
  def initialize(site)
    @site = site

    # @site.overage = the number of penalty intervals used this month
    @amount = (@site.overage_count * 5)
  end

  def call
    return unless amount > 0

    bill = create_bill_for_overage

    Bill.transaction do
      PayBill.new(bill).call
      reset_overage_count
    end

    put_to_slack_ok(bill)
  rescue => e
    put_to_slack_error(bill)
    Raven.capture_exception(e)
  end

  private

  attr_reader :site, :amount

  def put_to_slack_error(bill)
    put_to_slack("Attempting to bill #{ bill.id}: #{ site.url } for $#{ amount }... Failed")
  end

  def put_to_slack_ok(bill)
    put_to_slack("Attempting to bill #{ bill.id}: #{ site.url } for $#{ amount }... OK")
  end

  def create_bill_for_overage
    Bill.create!(
      subscription: last_paid_subscription,
      amount: @amount,
      description: 'Monthly View Limit Overage Fee',
      grace_period_allowed: true,
      bill_at: Time.current,
      start_date: Time.current,
      end_date: Time.current,
      one_time: true
    )
  end

  def last_paid_subscription
    site.bills.paid.last.subscription
  end

  def reset_overage_count
    @site.update!(overage_count: 0)
  end

  def put_to_slack(msg)
    PostToSlack.new(:billing, text: "[overage_fees] #{ msg }").call
  end
end
