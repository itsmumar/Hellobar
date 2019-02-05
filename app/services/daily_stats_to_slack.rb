class DailyStatsToSlack
  def initialize
    @new_sites =
    @churned_sites =
  end

  def call
    @net_new_sites =
    @total_paid_sites =
    calc_avg_rev_per_site
  end

  private

  attr_reader :new_sites, :churned_sites, :net_new_sites, :total_paid_sites


  def calc_avg_rev_per_site
    avg_rev =
    avg_rev_run_rate = 
  end

  def build_slack_message(new_sites, churned_sites, net_new_sites, total_paid_sites, avg_rev, avg_rev_run_rate)
    put_to_slack("Attempting to bill #{ bill.id }: #{ site.url } for $#{ amount }... Failed")
  end

  def put_to_slack(msg)
    PostToSlack.new(:billing, text: "[overage_fees] #{ msg }").call
  end
end
