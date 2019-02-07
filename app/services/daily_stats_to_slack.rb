class DailyStatsToSlack
  include ActionView::Helpers::NumberHelper

  def initialize
    yesterday_start = Date.yesterday.midnight
    yesterday_end = Date.yesterday.end_of_day
    @new_subs = Subscription.where('subscriptions.created_at > ? AND subscriptions.created_at < ?', yesterday_start, yesterday_end).non_free.paid.where('bills.amount > ?', 0).order(:site_id).distinct
    @new_free_subs = Subscription.where('subscriptions.created_at > ? AND subscriptions.created_at < ?', yesterday_start, yesterday_end).where(amount: 0).order(:site_id).distinct
  end

  def call
    calc_churned_sites
  end

  private

  attr_reader :new_subs, :new_free_subs

  def calc_churned_sites
    churned_site_ids = []
    failed_bills = []
    new_free_subs.each do |sub|
      site = Site.find(sub.site_id)
      if site.previous_subscription&.paid?
        if site.previous_subscription.bills.paid.last.nil?
          churned_site_ids << site.id
        elsif site.previous_subscription.bills.paid.last.amount > 1
          churned_site_ids << site.id

          failed_bills << site.id if site.previous_subscription.bills.last.status == 'failed'
        end
      end
    end
    @churned_sites = Site.where(id: churned_site_ids)
    gather_churned_subscriptions
  end

  def gather_churned_subscriptions
    churned_sub_ids = []
    @churned_sites.each do |site|
      churned_sub_ids << site.previous_subscription.id if site.previous_subscription
    end
    @churned_subs = Subscription.where(id: churned_sub_ids)
    calc_stats
  end

  def calc_stats
    new_sub_value = month_ize_amounts(@new_subs).sum.to_i
    churned_site_value = month_ize_amounts(@churned_subs).sum.to_i
    total_paid_sites = Subscription.non_free.paid.where('bills.amount > ?', 1)

    avg_rev_today = (new_sub_value / new_subs.count) unless new_subs.count == 0
    avg_rev_today = 0 if new_subs.count == 0
    total_paid_sites_count = total_paid_sites.count
    avg_rev_overall_per_user = (month_ize_amounts(total_paid_sites).sum.to_i / total_paid_sites_count)
    avg_rev_run_rate = ((total_paid_sites_count * avg_rev_overall_per_user) * 12)
    net_new_sites = new_subs.count - @churned_subs.count

    build_slack_message(new_subs.count, @churned_subs.count, net_new_sites, total_paid_sites_count, avg_rev_today, avg_rev_run_rate, new_sub_value, churned_site_value)
  end

  def month_ize_amounts(subscriptions)
    monthly_amounts = []
    subscriptions.each do |sub|
      monthly_amounts << sub.amount if sub.monthly?
      monthly_amounts << (sub.amount / 12) if sub.yearly?
    end
    monthly_amounts
  end

  # rubocop:disable Metrics/ParameterLists
  def build_slack_message(new_subs, churned_subs, net_new_subs, total_paid_sites_count, avg_rev_today, avg_rev_run_rate, new_sub_value, churned_site_value)
    # rubocop:disable Metrics/LineLength
    put_to_slack("\n\n\n\n___________________________________________________________\n___________________________________________________________\nSTATS FOR #{ Date.yesterday }:\nNew Subscriptions: #{ new_subs }\nChurned Subscriptions: #{ churned_subs }\nNet New Subscriptions: #{ net_new_subs }\nTotal Paid Sites: #{ number_with_delimiter(total_paid_sites_count) }\n Avg Monthly Rev Per New Site: #{ number_to_currency(avg_rev_today, precision: 0) }\n Avg Annual Run Rate: #{ number_to_currency(avg_rev_run_rate, precision: 0) }\nValue of New Subs: $#{ new_sub_value }\nValue Lost to Churn: $#{ churned_site_value }")
    # rubocop:enable Metrics/LineLength
  end
  # rubocop:enable Metrics/ParameterLists

  def put_to_slack(msg)
    PostToSlack.new(:daily_stats, text: msg.to_s).call
  end
end
