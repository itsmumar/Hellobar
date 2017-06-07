if ENV['COVERAGE'] || ENV['CI']
  require 'simplecov'
  require 'codecov'
  ENV['CODECOV_TOKEN'] = 'da2b3674-845d-4b2c-a60f-cea170294441'

  SimpleCov.formatter = SimpleCov::Formatter::Codecov if ENV['CIRCLECI'] == 'true'
  SimpleCov.command_name 'test:unit'
  SimpleCov.coverage_dir 'tmp/coverage'
  SimpleCov.start('rails') do
    add_group 'System', 'app/system'
    add_group 'Services', 'app/services'
    add_group 'Jobs', 'app/jobs'
    add_filter '/lib/legacy_migrator/'
    add_filter '/lib/legacy_migrator.rb'
    add_filter '/lib/test_site.rb'
  end
end
