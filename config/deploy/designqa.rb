server 'designqa.hellobar.com', user: 'hellobar', roles: %w(web db cron worker) # web1

set :ssh_options, forward_agent: true

# slack notification integration
set :slack_webhook, 'https://hooks.slack.com/services/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'
set :slack_channel, ['#hello-bar']
