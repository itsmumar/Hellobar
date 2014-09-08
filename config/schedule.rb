require "yaml"

PREFIX ="/mnt/deploy/current/log/"
set :output, { standard: PREFIX + "cron.log", error: PREFIX + "cron.error.log" }

env :PATH, ENV['PATH']

settings_file = "config/settings.yml"
settings_yaml = File.exists?(settings_file) ? YAML.load_file(settings_file) : {}

every 20.minutes, :roles => [:web] do
  runner "Hello::Tracking::InternalStatsHarvester.process_internal_stats"
end

every 15.minutes, :roles => [:web] do
  script "send_sqs_message #{settings_yaml["env_name"] || "edge"} 'contact_list:sync_all!'" 
end
