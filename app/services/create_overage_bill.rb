class CreateOverageBill
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
    Bill.create!(
      subscription: @site.active_subscription,
      amount: @amount,
      description: "Monthly View Limit Overage Fee",
      grace_period_allowed: true,
      bill_at: (DateTime.now + 1.hour),
      start_date: DateTime.now,
      end_date: DateTime.now
    )

    # reset the overage counter for the new month
    @site.update(overage_count: 0)
  end
end
