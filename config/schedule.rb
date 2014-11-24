require "yaml"

PREFIX ="/mnt/deploy/current/log/"
set :output, { standard: PREFIX + "cron.log", error: PREFIX + "cron.error.log" }

env :PATH, ENV['PATH']

settings_file = "config/settings.yml"
settings_yaml = File.exists?(settings_file) ? YAML.load_file(settings_file) : {}
env = settings_yaml["env_name"] || "edge"

# Dummy entry to keep crontabs empty on non-cron machines
every 10.days, :roles => [:web] do
  command "/bin/true" # no-op
end

every 20.minutes, :roles => [:cron] do
  script "send_sqs_message #{env} 'hello::tracking::internal_stats_harvester:process_internal_stats'"
end

every :thursday, :at => "10:00pm", :roles => [:cron] do
  rake "internal_metrics:email_weekly"
end

=begin
temporarily disabling
every :monday, :at => "8:00am", :roles => [:cron] do
  rake "email_digest:deliver_not_installed"
end

every :monday, :at => "8:30am", :roles => [:cron] do
  rake "email_digest:deliver_installed"
end
=end

every 24.hours, :at => "12:00am", :roles => [:cron] do
  rake "site:scripts:generate_all_separately"
end

every 24.hours, :at => "12:00am", :roles => [:cron] do
  rake "site:improve_suggestions:generate_all_separately"
end
