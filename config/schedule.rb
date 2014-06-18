PREFIX ="/mnt/deploy/current/log/"
set :output, { standard: PREFIX + "cron.log", error: PREFIX + "cron.error.log" }

env :PATH, ENV['PATH']

every 20.minutes, :roles => [:web] do
  runner "Hello::Tracking::InternalStatsHarvester.process_internal_stats"
end
