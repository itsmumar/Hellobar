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
    date = Date.current.beginning_of_month.midnight
    end_of_month = Date.current.end_of_month.end_of_day
    @mtd_paid = Subscription.where(created_at: date..end_of_month).non_free.where(trial_end_date: nil).count
    @mtd_trials = Subscription.where(created_at: date..end_of_month).non_free.count - @mtd_paid
    @mtd_elite = Subscription.where(created_at: date..end_of_month).non_free.elite.count
  end

  def calculate_today
    date = Time.zone.today
    @today_stats = Subscription.where(created_at: date.midnight..date.end_of_day).non_free.where(trial_end_date: nil).count
    @today_trials = Subscription.where(created_at: date.midnight..date.end_of_day).non_free.count - @today_stats
    @today_elite = Subscription.where(created_at: date.midnight..date.end_of_day).non_free.elite.count
  end

  def calculate_tomorrow
    yesterday = Date.yesterday
    @yesterday_stats = Subscription.where(created_at: yesterday.midnight..yesterday.end_of_day).non_free.where(trial_end_date: nil).count
    @yesterday_trials = Subscription.where(created_at: yesterday.midnight..yesterday.end_of_day).non_free.count - @yesterday_stats
    @yesterday_elite = Subscription.where(created_at: yesterday.midnight..yesterday.end_of_day).non_free.elite.count
  end

  def calculate_day_before
    day_before = (Date.yesterday - 1)
    @day_before_stats = Subscription.where(created_at: day_before.midnight..day_before.end_of_day).non_free.where(trial_end_date: nil).count
    @day_before_trials = Subscription.where(created_at: day_before.midnight..day_before.end_of_day).non_free.count - @day_before_stats
    @day_before_elite = Subscription.where(created_at: day_before.midnight..day_before.end_of_day).non_free.elite.count
  end
end
