require 'yaml'

lock '3.6.1'

set :application, 'hellobar'
set :repo_url, 'git@github.com:Hello-bar/hellobar_new.git'
set :deploy_to, '/mnt/deploy'
set :linked_files, %w[config/database.yml config/secrets.yml]
set :linked_dirs, %w[log]
set :branch, ENV['REVISION'] || ENV['BRANCH'] || 'master'
set :whenever_roles, %w[app db web]
set :keep_releases, 15

# Using `lambda` for lazy assigment. http://stackoverflow.com/a/25850619/1047207
set :ember_app_path, -> { "#{ release_path }/editor" }

set :slackistrano,
  channel: '#deploys',
  webhook: 'https://hooks.slack.com/services/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'

namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:web) do
      invoke 'deploy:reload_nginx_config'
      invoke 'deploy:restart_thin'
      invoke 'deploy:restart_monit'
    end
  end

  task :start_thin do
    on roles(:web) do
      as :hellobar do
        execute 'mkdir -p /mnt/deploy/shared/sockets'
        execute "cd #{ release_path } && bundle exec thin start -e #{ fetch :stage } -C config/thin/www.yml"
      end
    end
  end

  task :stop_thin do
    on roles(:web) do
      as :hellobar do
        execute 'mkdir -p /mnt/deploy/shared/sockets'
        execute "cd #{ release_path } && bundle exec thin stop -e #{ fetch :stage } -C config/thin/www.yml"
      end
    end
  end

  task :restart_thin do
    on roles(:web) do
      as :hellobar do
        execute 'mkdir -p /mnt/deploy/shared/sockets'
        execute "cd #{ release_path } && bundle exec thin restart -e #{ fetch :stage } -C config/thin/www.yml"
      end
    end
  end

  task :restart_monit do
    on roles(:web) do
      execute 'sudo service monit stop || sudo apt-get install monit'
      execute 'sudo rm /etc/monit/monitrc || true'
      execute "sudo cp /mnt/deploy/current/config/deploy/monitrc/#{ fetch :stage }.monitrc /etc/monit/monitrc"
      execute 'sudo chown root /etc/monit/monitrc'
      execute 'sudo service monit start'
      execute 'sudo monit restart all'
    end
  end

  before :cleanup_rollback, :restart_monit

  task :copy_additional_logrotate_files do
    on roles(:web) do
      execute "sudo cp #{ release_path }/config/deploy/logrotate.d/* /etc/logrotate.d/"
    end
  end

  desc 'Precompile static assets to be used for static site scripts recompilation'
  task :precompile_static_assets do
    on roles(:web, :worker) do
      within release_path do
        execute :rake, "site:scripts:precompile_static_assets RAILS_ENV=#{ fetch :stage }"
      end
    end
  end

  desc 'Generate and upload modules.js to S3'
  task :generate_modules do
    on roles(:cron) do
      within release_path do
        execute :rake, "site:scripts:generate_modules RAILS_ENV=#{ fetch :stage }"
      end
    end
  end

  # TODO: Move node and bower dependencies to some shared folder
  before 'assets:precompile', 'node:yarn_install'
  before 'assets:precompile', 'node:bower_install'
  before 'assets:precompile', 'ember:build'
  after 'assets:precompile', 'ember:move_non_digest_fonts' # TODO: fix fingerprinting on ember fonts
  after 'assets:precompile', 'precompile_static_assets'
  after 'precompile_static_assets', 'generate_modules'

  after :publishing, :restart
  after :publishing, :copy_additional_logrotate_files
  after :finished, 'tag_release:github'
  after :finished, 'trigger_automated_qa_tests'

  desc 'Starts maintenance mode'
  task :start_maintenance do
    on roles(:web) do
      invoke 'deploy:stop_nginx'
      invoke 'deploy:start_nginx_maintenance'
      invoke 'deploy:stop_thin'
      execute 'sudo monit stop shoryuken'
    end
  end

  desc 'Stops maintenance mode'
  task :stop_maintenance do
    on roles(:web) do
      invoke 'deploy:start_thin'
      invoke 'deploy:stop_nginx'
      invoke 'deploy:start_nginx_web'
      execute 'sudo monit start shoryuken'
    end
  end

  task :start_nginx_web do
    on roles(:web) do
      execute 'sudo nginx -c /mnt/deploy/current/config/nginx/web.conf'
    end
  end

  task :stop_nginx do
    on roles(:web) do
      execute "sudo kill `cat /mnt/deploy/shared/pids/nginx.pid` || echo 'no nginx'"
    end
  end

  task :reload_nginx_config do
    on roles(:web) do
      # uses kill, but actually just reloads the config.
      as :hellobar do
        execute 'mkdir -p /mnt/deploy/shared/pids'
        execute '/usr/bin/env bash -c "if test -f /mnt/deploy/shared/pids/nginx.pid; then sudo kill -HUP `cat /mnt/deploy/shared/pids/nginx.pid`; else sudo nginx -c /mnt/deploy/current/config/nginx/web.conf; fi"'
      end
    end
  end

  task :start_nginx_maintenance do
    on roles(:web) do
      execute 'sudo nginx -c /mnt/deploy/current/config/nginx/maintenance.conf'
    end
  end
end

namespace :prerequisites do
  desc 'Install necessary global ubuntu/yarn packages'
  task :install do
    on roles(:web) do
      execute 'sudo apt-get -y install imagemagick'

      execute 'curl -sL https://deb.nodesource.com/setup | sudo bash -'
      execute 'sudo apt-get install -y nodejs'
      execute 'sudo yarn global add bower'
      execute 'sudo yarn global add ember-cli'
    end
  end
end

namespace :ember do
  desc 'Build Ember application'
  task :build do
    on roles(:web) do
      execute "cd #{ fetch(:ember_app_path) } && ember build --environment=production >/dev/null"
    end
  end

  desc 'Move non digested specific fonts to public'
  task :move_non_digest_fonts do
    on roles(:web) do
      execute "cd #{ fetch(:release_path) } && cp app/assets/fonts/* public/assets/"
    end
  end
end

namespace :node do
  desc 'Install node modules'
  task :yarn_install do
    on roles(:web) do
      execute "cd #{ fetch(:ember_app_path) } && yarn install --frozen-lockfile"
    end
  end

  desc 'Install bower components'
  task :bower_install do
    on roles(:web) do
      execute "cd #{ fetch(:ember_app_path) } && bower install >/dev/null"
    end
  end
end

namespace :tag_release do
  desc 'Tag release at GitHub'
  task :github do
    next if dry_run?

    run_locally do
      current_revision = fetch :current_revision

      strategy.git 'remote update'
      strategy.git "branch -f #{ fetch :stage } #{ current_revision }"
      strategy.git "push -f origin #{ fetch :stage }"
    end
  end
end

desc 'Run automated QA tests after edge and production deployments'
task :trigger_automated_qa_tests do
  run_locally do
    stage = fetch :stage

    if !dry_run? && %i[edge production].include?(stage)
      info "Trigger automated QA tests on #{ stage }"

      execute <<~CMD
        curl --data '{"build_parameters": {"QA_ENV": "#{ stage }"}}' \
             -X POST https://circleci.com/api/v1.1/project/github/Hello-bar/hellobar_qa_java/tree/master \
             --header "Content-Type: application/json" \
             --silent -u 73ba0635bbc31e2b342dff9664810f1e13e71556: > /dev/null
      CMD
    else
      info 'Skipping automated QA tests'

      next
    end
  end
end
