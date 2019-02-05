class DailyStatsToSlack
  def initialize
    yesterday_start = Date.yesterday.midnight
    yesterday_end = Date.yesterday.end_of_day
    @new_subs = Subscription.where(created_at: yesterday_start..yesterday_end).non_free.where(trial_end_date: nil)
    @churned_subs =
  end

  def call
    @net_new_subs =
    @total_paid_sites =
    calc_avg_rev_per_site
  end

  private

  attr_reader :new_subs, :churned_subs, :net_new_subs, :total_paid_sites


  def calc_avg_rev_per_site
    avg_rev =
    avg_rev_run_rate =
  end

  def build_slack_message(new_subs, churned_subs, net_new_subs, total_paid_sites, avg_rev, avg_rev_run_rate)
    put_to_slack("Attempting to bill #{ bill.id }: #{ site.url } for $#{ amount }... Failed")
  end

  def put_to_slack(msg)
    PostToSlack.new(:billing, text: "[overage_fees] #{ msg }").call
  end
end
