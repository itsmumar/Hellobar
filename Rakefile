# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks
# Rake::Task[:teaspoon].clear if defined?(Teaspoon)

# task :teaspoon do
#   puts "[!] Overrode teaspoon default task to force test env.\nExecuting `RAILS_ENV=test bundle exec teaspoon`"
#   exit system('RAILS_ENV=test bundle exec teaspoon')
# end

task default: [:spec] #, :teaspoon]
