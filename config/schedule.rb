require "yaml"

PREFIX ="/mnt/deploy/current/log/"
set :output, { standard: PREFIX + "cron.log", error: PREFIX + "cron.error.log" }

env :PATH, ENV['PATH']

settings_file = "config/settings.yml"
settings_yaml = File.exists?(settings_file) ? YAML.load_file(settings_file) : {}
env = settings_yaml["env_name"] || "edge"

every 20.minutes, :roles => [:web] do
  runner "Hello::Tracking::InternalStatsHarvester.process_internal_stats"
end

every 20.minutes, :roles => [:web] do
  script "send_sqs_message #{env} 'hello::tracking::internal_stats_harvester:process_internal_stats'"
end
