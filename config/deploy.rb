require 'yaml'

lock '3.6.1'

set :application, 'hellobar'
set :repo_url, 'git@github.com:Hello-bar/hellobar_new.git'
set :deploy_to, '/mnt/deploy'
set :linked_files, %w(config/database.yml config/secrets.yml config/settings.yml config/application.yml)
set :linked_dirs, %w(log tmp/pids)
set :rails_env, 'production'
set :branch, ENV['REVISION'] || ENV['BRANCH'] || 'master'
set :whenever_roles, %w(app db web)
set :keep_releases, 15

# Using `lambda` for lazy assigment. http://stackoverflow.com/a/25850619/1047207
set :ember_app_path, -> { "#{ release_path }/editor" }

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

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
      invoke 'deploy:restart_queue_workers'
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

  task :restart_thin do
    on roles(:web) do
      as :hellobar do
        execute 'mkdir -p /mnt/deploy/shared/sockets'
        execute "cd #{ release_path } && ./bin/load_env -- bundle exec thin restart -C config/thin/www.yml"
      end
    end
  end

  task :stop_thin do
    on roles(:web) do
      as :hellobar do
        execute 'mkdir -p /mnt/deploy/shared/sockets'
        execute "cd #{ release_path } && ./bin/load_env -- bundle exec thin stop -C config/thin/www.yml"
      end
    end
  end

  task :start_thin do
    on roles(:web) do
      as :hellobar do
        execute 'mkdir -p /mnt/deploy/shared/sockets'
        execute "cd #{ release_path } && ./bin/load_env -- bundle exec thin start -C config/thin/www.yml"
      end
    end
  end

  task :restart_queue_workers do
    on roles(:web) do
      as :hellobar do
        execute "cd #{ release_path } && RAILS_ENV=production bundle exec rake queue_worker:restart"
      end
    end
  end

  task :stop_queue_workers do
    on roles(:web) do
      as :hellobar do
        execute "cd #{ release_path } && RAILS_ENV=production bundle exec rake queue_worker:stop"
      end
    end
  end

  task :start_queue_workers do
    on roles(:web) do
      as :hellobar do
        execute "cd #{ release_path } && RAILS_ENV=production bundle exec rake queue_worker:start"
      end
    end
  end

  task :restart_monit do
    on roles(:web) do
      execute 'sudo service monit stop || sudo apt-get install monit'
      execute 'sudo rm /etc/monit/monitrc || true'
      execute "sudo cp /mnt/deploy/current/config/deploy/monitrc/#{ fetch(:stage) }.monitrc /etc/monit/monitrc"
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

  # TODO: Move node and bower dependencies to some shared folder
  before 'assets:precompile', 'node:npm_install'
  before 'assets:precompile', 'node:bower_install'
  before 'assets:precompile', 'ember:build'
  after 'assets:precompile', 'ember:move_non_digest_fonts' # TODO: fix fingerprinting on ember fonts
  after 'assets:precompile', 'precompile_static_assets'

  after :publishing, :tag_release
  after :publishing, :restart
  after :publishing, :copy_additional_logrotate_files

  desc 'Precompile static assets for site'
  task :precompile_static_assets do
    on roles(:web, :worker) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, 'site:scripts:precompile_static_assets'
        end
      end
    end
  end

  desc 'Starts maintenance mode'
  task :start_maintenance do
    on roles(:web) do
      invoke 'deploy:stop_nginx'
      invoke 'deploy:start_nginx_maintenance'
      invoke 'deploy:stop_thin'
      invoke 'deploy:stop_queue_workers'
    end
  end

  desc 'Stops maintenance mode'
  task :stop_maintenance do
    on roles(:web) do
      invoke 'deploy:start_thin'
      invoke 'deploy:stop_nginx'
      invoke 'deploy:start_nginx_web'
      invoke 'deploy:start_queue_workers'
    end
  end

  task :stop_nginx do
    on roles(:web) do
      execute "sudo kill `cat /mnt/deploy/shared/pids/nginx.pid` || echo 'no nginx'"
    end
  end

  task :start_nginx_web do
    on roles(:web) do
      execute 'sudo nginx -c /mnt/deploy/current/config/nginx/web.conf'
    end
  end

  task :start_nginx_maintenance do
    on roles(:web) do
      execute 'sudo nginx -c /mnt/deploy/current/config/nginx/maintenance.conf'
    end
  end

  task :tag_release do
    return if dry_run?

    run_locally do
      stage = fetch :stage
      current_revision = fetch :current_revision

      strategy.git 'remote update'
      strategy.git "branch -f #{ stage } #{ current_revision }"
      strategy.git "push -f origin #{ stage }"
    end
  end
end

namespace :prerequisites do
  desc 'Install necessary ubuntu packages'
  task :install do
    on roles(:web) do
      execute 'sudo apt-get -y install imagemagick'

      execute 'curl -sL https://deb.nodesource.com/setup | sudo bash -'
      execute 'sudo apt-get install -y nodejs'
      execute 'sudo npm install -g bower'
      execute 'sudo npm install -g ember-cli'
    end
  end
end
