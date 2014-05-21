lock "3.2.1"

set :application, "hellobar"
set :repo_url, "git@github.com:PolymathicMedia/hellobar_new.git"
set :deploy_to, "/mnt/deploy"
set :linked_files, %w{config/database.yml}

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

namespace :deploy do

  desc "Restart application"
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      # execute :touch, release_path.join("tmp/restart.txt")
    end
  end

  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, "cache:clear"
      # end
    end
  end

end
