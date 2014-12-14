require 'yaml'

lock "3.2.1"

set :application, "hellobar"
set :repo_url, "git@github.com:teampolymathic/hellobar_new.git"
set :deploy_to, "/mnt/deploy"
set :linked_files, %w{config/database.yml config/secrets.yml config/settings.yml config/application.yml}
set :linked_dirs, %w{log tmp/pids}
set :rails_env, "production"
set :ssh_options, { :forward_agent => true }
set :branch, ENV["REVISION"] || ENV["BRANCH"] || "master"
set :whenever_roles, %w(app db web)

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

namespace :deploy do
  desc "Restart application"
  task :restart do
    on roles(:web) do
      invoke "deploy:reload_nginx_config"
      invoke "deploy:restart_thin"
      invoke "deploy:restart_monit"
      invoke "deploy:restart_queue_workers"
    end
  end

  task :reload_nginx_config do
    on roles(:web) do
      # uses kill, but actually just reloads the config.
      as :hellobar do
        execute "mkdir -p /mnt/deploy/shared/pids"
        execute '/usr/bin/env bash -c "if test -f /mnt/deploy/shared/pids/nginx.pid; then sudo kill -HUP `cat /mnt/deploy/shared/pids/nginx.pid`; else sudo nginx -c /mnt/deploy/current/config/nginx/web.conf; fi"'
      end
    end
  end

  task :restart_thin do
    on roles(:web) do
      as :hellobar do
        execute "mkdir -p /mnt/deploy/shared/sockets"
        execute "cd #{release_path} && ./bin/load_env -- bundle exec thin restart -C config/thin/www.yml"
      end
    end
  end

  task :stop_thin do
    on roles(:web) do
      as :hellobar do
        execute "mkdir -p /mnt/deploy/shared/sockets"
        execute "cd #{release_path} && ./bin/load_env -- bundle exec thin stop -C config/thin/www.yml"
      end
    end
  end

  task :start do
    on roles(:web) do
      as :hellobar do
        execute "mkdir -p /mnt/deploy/shared/sockets"
        execute "cd #{release_path} && ./bin/load_env -- bundle exec thin start -C config/thin/www.yml"
      end
    end
  end

  task :restart_queue_workers do
    on roles(:web) do
      as :hellobar do
        execute "cd #{release_path} && RAILS_ENV=production bundle exec rake queue_worker:restart"
      end
    end
  end

  task :stop_queue_workers do
    on roles(:web) do
      as :hellobar do
        execute "cd #{release_path} && RAILS_ENV=production bundle exec rake queue_worker:stop"
      end
    end
  end

  task :stop_queue_workers do
    on roles(:web) do
      as :hellobar do
        execute "cd #{release_path} && RAILS_ENV=production bundle exec rake queue_worker:start"
      end
    end
  end

  task :restart_monit do
    on roles(:web) do
      execute "sudo service monit stop || sudo apt-get install monit"
      execute "sudo rm /etc/monit/monitrc || true"
      execute "sudo ln -s /mnt/deploy/current/config/deploy/monitrc/#{fetch(:stage)}.monitrc /etc/monit/monitrc"
      execute "sudo chown root /etc/monit/monitrc"
      execute "sudo service monit start"
      execute "sudo monit restart all"
    end
  end

  task :copy_additional_logrotate_files do
    on roles(:web) do
      execute "sudo cp #{release_path}/config/deploy/logrotate.d/guaranteed_queue /etc/logrotate.d/"
    end
  end

  after :publishing, :restart
  after :publishing, :copy_additional_logrotate_files

  desc "Starts maintenance mode"
  task :start_maintenance do
    on roles(:web) do
      invoke "deploy:stop_nginx"
      invoke "deploy:start_nginx_maintenance"
      invoke "deploy:stop_thin"
      invoke "deploy:stop_queue_workers"
    end
  end

  desc "Stops maintenance mode"
  task :stop_maintenance do
    on roles(:web) do
      invoke "deploy:start_thin"
      invoke "deploy:stop_nginx"
      invoke "deploy:start_nginx_web"
      invoke "deploy:start_queue_workers"
    end
  end

  task :stop_nginx do
    on roles(:web) do
      run "sudo kill `cat /mnt/deploy/shared/pids/nginx.pid` || echo 'no nginx'"
    end
  end

  task :start_nginx_web do
    on roles(:web) do
      run "sudo nginx -c /mnt/deploy/current/config/nginx/web.conf"
    end
  end

  task :start_nginx_maintenance do
    on roles(:web) do
      run "sudo nginx -c /mnt/deploy/current/config/nginx/maintenance.conf"
    end
  end
end
