class CreateAndPayOverageBill
  def initialize(site)
    @site = site
    @amount = (@site.overage_count * 5) # @site.overage = the number of penalty intervals used this month
  end

  def call
    create_bill_for_overage
  end

  private

  attr_reader :site

  def create_bill_for_overage
    bill = Bill.create!(
      subscription: @site.subscriptions.last,
      amount: @amount,
      description: 'Monthly View Limit Overage Fee',
      grace_period_allowed: true,
      bill_at: (Time.current + 1.hour),
      start_date: Time.current,
      end_date: Time.current,
      one_time: true
    )

    # reset the overage counter for the new month
    @site.update(overage_count: 0)

    PayBill.new(bill).call
  end
end
