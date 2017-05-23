require 'yaml'

PREFIX = '/mnt/deploy/current/log/'.freeze
set :output, standard: PREFIX + 'cron.log', error: PREFIX + 'cron.error.log'

env :PATH, ENV['PATH']

# All times are in UTC
every :friday, at: '2:00pm', roles: [:cron] do
  rake 'internal_metrics:email_weekly'
end

every :day, at: '1:00pm', roles: [:cron] do
  rake 'billing:run'
end

every :monday, at: '3:00pm', roles: [:cron] do
  rake 'email_digest:deliver'
end

every 24.hours, at: '12:00am', roles: [:cron] do
  rake 'site:scripts:regenerate_all_active'
end

every 24.hours, at: '1:00pm', roles: [:cron] do
  rake 'referrals:send_followups'
end

every 2.hours, roles: [:cron] do
  rake 'onboarding_campaigns:deliver'
end

every 1.hour, roles: [:cron] do
  rake 'backend:adjust_dynamo_db_capacity[recent_throttled_only]'
  rake 'cloudwatch_metrics:create_alarms'
end

every 6.hours, roles: [:cron] do
  rake 'backend:adjust_dynamo_db_capacity[all]'
end

every 1.hour, roles: %i[web worker] do
  command 'sudo /usr/bin/monit stop shoryuken ; sleep 30; sudo /usr/bin/monit start shoryuken'
end

every 5.minutes, roles: %i[web worker] do
  rake 'cloudwatch_metrics:send'
end
