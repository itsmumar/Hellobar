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
    @total_paid_sites_count = total_paid_sites.count
    avg_rev_overall_per_user = (month_ize_amounts(total_paid_sites).sum.to_i / @total_paid_sites_count)
    @avg_rev_run_rate = ((@total_paid_sites_count * avg_rev_overall_per_user) * 12)
    @net_new_sites = new_subs.count - @churned_subs.count

    build_hash(new_subs.count, @churned_subs.count, avg_rev_today, new_sub_value, churned_site_value)
  end

  def build_hash(new_subs_count, churned_sites_count, avg_rev_today, new_sub_value, churned_site_value)
    options = {}
    options[:new_subs_count] = new_subs_count
    options[:churned_sites_count] = churned_sites_count
    options[:net_new_sites] = @net_new_sites
    options[:total_paid_sites_count] = number_with_delimiter(@total_paid_sites_count)
    options[:avg_rev_today] = number_to_currency(avg_rev_today, precision: 0)
    options[:avg_rev_run_rate] = number_to_currency(@avg_rev_run_rate, precision: 0)
    options[:new_sub_value] = number_to_currency(new_sub_value, precision: 0)
    options[:churned_site_value] = number_to_currency(churned_site_value, precision: 0)
    build_slack_message(options)
  end

  def month_ize_amounts(subscriptions)
    monthly_amounts = []
    subscriptions.each do |sub|
      monthly_amounts << sub.amount if sub.monthly?
      monthly_amounts << (sub.amount / 12) if sub.yearly?
    end
    monthly_amounts
  end

  def build_slack_message(options = {})
    msg = "STATS FOR #{ Date.yesterday }:\nNew Subscriptions: #{ options[:new_subs_count] }\nChurned Subscriptions: #{ options[:churned_sites_count] }\nNet New Subscriptions: #{ options[:net_new_sites] }\nTotal Paid Sites: #{ options[:total_paid_sites_count] }\nAvg Monthly Rev Per New Site: #{ options[:avg_rev_today] }\n Avg Annual Run Rate: #{ options[:avg_rev_run_rate] }\nValue of New Subs: #{ options[:new_sub_value] }\nValue Lost to Churn: #{ options[:churned_site_value] }"
    put_to_slack(msg)
  end

  def put_to_slack(msg)
    PostToSlack.new(:daily_stats, text: msg.to_s).call
  end
end
