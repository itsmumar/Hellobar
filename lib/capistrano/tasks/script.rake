namespace :script do
  task :precompile do
    on roles(:web, :worker) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, 'site:scripts:precompile'
        end
      end
    end
  end
end
