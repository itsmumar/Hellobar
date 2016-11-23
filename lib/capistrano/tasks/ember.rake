namespace :ember do
	desc 'Build Ember Application'
	task :build do
		on roles(:web) do
			execute "cd #{fetch(:ember_app_path)} && ember build --environment=production"
		end
	end
end
