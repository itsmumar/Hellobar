lock "3.2.1"

set :application, "hellobar"
set :repo_url, "git@github.com:teampolymathic/hellobar_new.git"
set :deploy_to, "/mnt/deploy"
set :linked_files, %w{config/database.yml config/secrets.yml config/settings.yml}
set :linked_dirs, %w{log tmp/pids}
set :rails_env, "production"
set :ssh_options, { :forward_agent => true }
set :branch, ENV["REVISION"] || ENV["BRANCH"] || "master"

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call


namespace :deploy do
  desc "Restart application"
  task :restart do
    on roles(:web) do
      invoke "deploy:reload_nginx_config"
      invoke "deploy:restart_thin"
      invoke "deploy:restart_monit"
    end
  end

  task :reload_nginx_config do
    on roles(:web) do
      # uses kill, but actually just reloads the config.
      as :hellobar do
        execute "sudo kill -HUP `cat /mnt/deploy/shared/pids/nginx.pid` || sudo nginx -c /mnt/deploy/current/config/nginx/#{fetch(:stage)}.web.conf"
      end
    end
  end

  task :restart_thin do
    on roles(:web) do
      as :hellobar do
        execute "mkdir -p /mnt/deploy/shared/sockets"
        execute "cd #{release_path} && bundle exec thin restart -C config/thin/www.yml"
      end
    end
  end

  task :restart_monit do
    on roles(:web) do
      execute "sudo service monit stop || sudo apt-get install monit"
      execute "sudo rm /etc/monit/monitrc"
      execute "sudo ln -s /mnt/deploy/current/config/deploy/monitrc /etc/monit/monitrc"
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
end
