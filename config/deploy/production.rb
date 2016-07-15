server '54.235.76.197', user: 'hellobar', roles: %w{web db cron} # web1
server '23.21.249.113', user: 'hellobar', roles: %w{web}         # web2
server '54.211.192.176', user: 'hellobar', roles: %w{web worker} # worker1

set :ssh_options, {
  forward_agent: true
}

# slack notification integration
set :slack_webhook, "https://hooks.slack.com/services/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"
set :slack_channel, ['#hello-bar', '#hb-deployments']
