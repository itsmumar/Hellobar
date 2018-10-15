class StatsController < ApplicationController
  before_action :authenticate_user!

  def index
    date = Date.today
    @today_stats = Subscription.where(created_at:date.midnight..date.end_of_day).non_free.where(trial_end_date: nil).count
    @today_trials = Subscription.where(created_at:date.midnight..date.end_of_day).non_free.count - @today_stats
    @today_elite = Subscription.where(created_at:date.midnight..date.end_of_day).non_free.elite.count

    yesterday = Date.yesterday
    @yesterday_stats = Subscription.where(created_at:yesterday.midnight..yesterday.end_of_day).non_free.where(trial_end_date: nil).count
    @yesterday_trials = Subscription.where(created_at:yesterday.midnight..yesterday.end_of_day).non_free.count - @yesterday_stats
    @yesterday_elite = Subscription.where(created_at:yesterday.midnight..yesterday.end_of_day).non_free.elite.count

    day_before = (Date.yesterday - 1)
    @day_before_stats = Subscription.where(created_at:day_before.midnight..day_before.end_of_day).non_free.where(trial_end_date: nil).count
    @day_before_trials = Subscription.where(created_at:day_before.midnight..day_before.end_of_day).non_free.count - @day_before_stats
    @day_before_elite = Subscription.where(created_at:day_before.midnight..day_before.end_of_day).non_free.elite.count
  end
end
