require "yaml"

PREFIX ="/mnt/deploy/current/log/"
set :output, { standard: PREFIX + "cron.log", error: PREFIX + "cron.error.log" }

env :PATH, ENV['PATH']

settings_file = "config/settings.yml"
settings_yaml = File.exists?(settings_file) ? YAML.load_file(settings_file) : {}
env = settings_yaml["env_name"] || "edge"

every 20.minutes, :roles => [:web] do
  script "send_sqs_message #{env} 'hello::tracking::internal_stats_harvester:process_internal_stats'"
end

every :monday, :at => "8:00am", :roles => [:web] do
  rake "email_digest:deliver_not_installed"
end

every :monday, :at => "8:30am", :roles => [:web] do
  rake "email_digest:deliver_installed"
end

every 24.hours, :at => "12:00am", :roles => [:web] do
  rake "site:scripts:generate_all_separately"
end

every 24.hours, :at => "12:00am", :roles => [:web] do
  rake "site:improve_suggestions:generate_all_separately"
end
