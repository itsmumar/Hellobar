# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

Rake::Task[:spec].enhance do
  Rake::Task[:teaspoon].invoke
end

task :set_test_env do
  Rails.env = "test"
end

Rake::Task[:teaspoon].clear_prerequisites
Rake::Task[:teaspoon].enhance([:set_test_env, :environment])
