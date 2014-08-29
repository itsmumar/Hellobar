PREFIX ="/mnt/deploy/current/log/"
set :output, { standard: PREFIX + "cron.log", error: PREFIX + "cron.error.log" }

env :PATH, ENV['PATH']

# TODO: Rails environment is not loaded in this file, so need a different way to access env_name
# every 20.minutes, :roles => [:web] do
#   runner "Hello::Tracking::InternalStatsHarvester.process_internal_stats"
# end
