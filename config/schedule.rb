require 'yaml'

PREFIX = '/mnt/deploy/current/log/'.freeze
set :output, standard: PREFIX + 'cron.log', error: PREFIX + 'cron.error.log'

env :PATH, ENV['PATH']

############################### ALL TIMES ARE IN UTC ####################################

every 1.month, at: '1:00pm', roles: [:cron] do
  # generate overage fee bills to be paid in next billing run
  rake 'overage_fees:run'
end

every 1.month, at: '1:15pm', roles: [:cron] do
  # reset the warning_email_sent fields to `true` on sites
  rake 'reset_email_sent_fields:run'
end

every :day, at: '1:30pm', roles: [:cron] do
  rake 'intercom_refresh:start'
end

every :day, at: '2:00pm', roles: [:cron] do
  rake 'billing:run'
end

every :day, at: '2:15pm', roles: [:cron] do
  rake 'monthly_views_tracker:check'
end

every :monday, at: '2:30pm', roles: [:cron] do
  rake 'mailing:send_weekly_digest'
end

every :tuesday, at: '3:00pm', roles: [:cron] do
  rake 'internal_metrics:summary'
end

every 24.hours, at: '12:00pm', roles: [:cron] do
  rake 'intercom:prune_inactive_users'
end

every 24.hours, at: '1:00pm', roles: [:cron] do
  rake 'referrals:send_followups'
end

every 7.minutes, roles: [:cron] do
  rake 'site:scripts:regenerate:sample_of_least_recently_regenerated_active_sites'
end

every 24.hours, at: '12:00am', roles: [:cron] do
  rake 'site:scripts:install_check:recently_uninstalled'
end

every 24.hours, at: '1:00am', roles: [:cron] do
  rake 'site:scripts:install_check:uninstalled_but_recently_modified'
end

every 24.hours, at: '2:00am', roles: [:cron] do
  rake 'site:scripts:install_check:recently_created_not_installed'
end

every 5.minutes, roles: %i[web worker] do
  rake 'cloudwatch_metrics:send'
end

every 1.hour, roles: [:cron] do
  rake 'system_metrics:upload'
end
