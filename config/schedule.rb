require "yaml"

PREFIX ="/mnt/deploy/current/log/"
set :output, { standard: PREFIX + "cron.log", error: PREFIX + "cron.error.log" }

env :PATH, ENV['PATH']

settings_file = "config/settings.yml"
settings_yaml = File.exists?(settings_file) ? YAML.load_file(settings_file) : {}
env = settings_yaml["env_name"] || "edge"

every 20.minutes, :roles => [:cron] do
  rake "internal_metrics:process"
end

if env == "production"
  every :friday, :at => "2:00pm", :roles => [:cron] do
    rake "internal_metrics:email_weekly"
  end
  every :day, :at => "1:00pm", :roles => [:cron] do
    rake "billing:run"
  end
end

# Note: time is UTC
every :monday, :at => "3:00pm", :roles => [:cron] do
  rake "email_digest:deliver"
end

every 24.hours, :at => "12:00am", :roles => [:cron] do
  rake "site:scripts:generate_all_separately"
end

every 24.hours, :at => "12:00am", :roles => [:cron] do
  rake "site:improve_suggestions:generate_all_separately"
end

every 24.hours, :at => "12:00am", :roles => [:web] do
  rake "queue_worker:restart"
end
