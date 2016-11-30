namespace :node do
	desc 'Install node modules'
	task :npm_install do
		on roles(:web) do
			execute "cd #{fetch(:ember_app_path)} && npm install"
		end
	end

	desc 'Install bower components'
	task :bower_install do
		on roles(:web) do
			execute "cd #{fetch(:ember_app_path)} && bower install"
		end
	end
end
