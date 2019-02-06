namespace :daily_stats_to_slack do
  desc 'Send daily churn stats to slack'
  task run: :environment do
    DailyStatsToSlack.new.call
  end
end
