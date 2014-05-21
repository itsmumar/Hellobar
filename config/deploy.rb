lock "3.2.1"

set :application, "hellobar"
set :repo_url, "git@github.com:PolymathicMedia/hellobar_new.git"
set :deploy_to, "/mnt/deploy"
set :linked_files, %w{config/database.yml}
set :rails_env, "production"

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

namespace :deploy do
  desc "Restart application"
  task :restart do
    on roles(:web), in: :sequence, wait: 5 do
      reload_nginx_config
      restart_thin
    end
  end

  after :publishing, :restart

  task :reload_nginx_config do
    # uses kill, but actually just reloads the config.
    run "sudo kill -HUP `cat /mnt/deploy/shared/pids/nginx.pid` || sudo nginx -c /mnt/deploy/current/config/nginx/#{stage}.web.conf"
  end

  task :restart_thin, :roles=>:web do
    run "cd #{latest_release} && bundle exec sudo thin restart -C config/thin/www.yml"
  end
end
