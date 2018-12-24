class StatsController < ApplicationController
  before_action :authenticate_user!
  before_action :calculate_today, only: [:index]
  before_action :calculate_tomorrow, only: [:index]
  before_action :calculate_day_before, only: [:index]
  before_action :mtd, only: [:index]

  def index
  end

  private

  def mtd
    beginning_of_webinars = Date.parse('October 5, 2018').midnight
    date = Date.current.beginning_of_month.midnight
    end_of_month = Date.current.end_of_month.end_of_day
    @mtd_paid = Subscription.where(created_at: date..end_of_month).non_free.where(trial_end_date: nil).count
    @mtd_trials = Subscription.where(created_at: date..end_of_month).non_free.count - @mtd_paid
    @mtd_converted_trials = calculate_trials(date, end_of_month)
    @mtd_trial_cancels = calculate_trial_cancels(date, end_of_month)
    @mtd_elite = Subscription.where(created_at: date..end_of_month).non_free.elite.count
    @mtd_custom = Subscription.where(created_at: date..end_of_month).non_free.custom.count
    @mtd_pro_special = Subscription.where(created_at: date..end_of_month).non_free.pro_special.count
    @all_converted = calculate_trials(beginning_of_webinars, end_of_month)
    @all_trial_cancels = calculate_trial_cancels(beginning_of_webinars, end_of_month)
  end

  def calculate_today
    date = Time.zone.today
    @today_stats = Subscription.where(created_at: date.midnight..date.end_of_day).non_free.where(trial_end_date: nil).count
    @today_trials = Subscription.where(created_at: date.midnight..date.end_of_day).non_free.count - @today_stats
    @today_elite = Subscription.where(created_at: date.midnight..date.end_of_day).elite.count
    @today_custom = Subscription.where(created_at: date.midnight..date.end_of_day).custom.count
    @today_pro_special = Subscription.where(created_at: date.midnight..date.end_of_day).pro_special.count
  end

  def calculate_tomorrow
    yesterday = Date.yesterday
    @yesterday_stats = Subscription.where(created_at: yesterday.midnight..yesterday.end_of_day).non_free.where(trial_end_date: nil).count
    @yesterday_trials = Subscription.where(created_at: yesterday.midnight..yesterday.end_of_day).non_free.count - @yesterday_stats
    @yesterday_elite = Subscription.where(created_at: yesterday.midnight..yesterday.end_of_day).non_free.elite.count
    @yesterday_custom = Subscription.where(created_at: yesterday.midnight..yesterday.end_of_day).custom.count
    @yesterday_pro_special = Subscription.where(created_at: yesterday.midnight..yesterday.end_of_day).pro_special.count
  end

  def calculate_day_before
    day_before = (Date.yesterday - 1)
    @day_before_stats = Subscription.where(created_at: day_before.midnight..day_before.end_of_day).non_free.where(trial_end_date: nil).count
    @day_before_trials = Subscription.where(created_at: day_before.midnight..day_before.end_of_day).non_free.count - @day_before_stats
    @day_before_elite = Subscription.where(created_at: day_before.midnight..day_before.end_of_day).non_free.elite.count
    @day_before_custom = Subscription.where(created_at: day_before.midnight..day_before.end_of_day).custom.count
    @day_before_pro_special = Subscription.where(created_at: day_before.midnight..day_before.end_of_day).pro_special.count
  end

  def calculate_trials(start_date, end_date)
    subs = []
    Subscription.where(trial_end_date: start_date..end_date).each do |sub|
      sub.bills.each do |bill|
        subs << sub.id if bill.amount.to_i != 0 && bill.status == 'paid'
      end
    end
    subs = subs.uniq.count
  end

  def calculate_trial_cancels(start_date, end_date)
    subs = []
    Subscription.where(trial_end_date: start_date..end_date).each do |sub|
      subs << sub.id if sub.site.current_subscription&.free?
    end
    subs = subs.uniq.count
  end
end
