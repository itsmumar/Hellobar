namespace :deploy do

  desc 'Compile assets'
  task :compile_assets => [:set_rails_env] do
    # invoke 'deploy:assets:precompile'
    invoke 'deploy:assets:precompile_local'
    invoke 'deploy:assets:backup_manifest'
  end

  namespace :assets do
    desc "Precompile assets locally and then rsync to web servers"

    ember_app_name = "editor"
    local_ember_assets_dir = "./public/assets/"

    task :precompile_local do
      # compile assets locally
      run_locally do
        execute "cd #{ember_app_name} && ember build --environment=production"
        execute "RAILS_ENV=#{fetch(:stage)} bundle exec rake assets:precompile"
      end

      # rsync to each server
      on roles( fetch(:assets_roles, [:web]) ) do
        # this needs to be done outside run_locally in order for host to exist
        remote_assets_dir = "#{host.user}@#{host.hostname}:#{release_path}/public/assets/"

        run_locally { execute "rsync -av --delete #{local_ember_assets_dir} #{remote_assets_dir}" }
      end

      # clean up
      run_locally { execute "rm -rf #{local_ember_assets_dir}" }
    end
  end
end
