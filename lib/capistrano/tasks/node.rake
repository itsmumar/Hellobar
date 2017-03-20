namespace :node do
  desc 'Install node modules'
  task :npm_install do
    on roles(:web) do
      execute "cd #{ fetch(:ember_app_path) } && npm install >/dev/null"
    end
  end

  desc 'Install bower components'
  task :bower_install do
    on roles(:web) do
      execute "cd #{ fetch(:ember_app_path) } && bower install >/dev/null"
    end
  end
end
