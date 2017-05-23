if ENV['COVERAGE'] || ENV['CI']
  require 'simplecov'
  require 'codecov'
  ENV['CODECOV_TOKEN'] = 'da2b3674-845d-4b2c-a60f-cea170294441'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov if ENV['CIRCLECI'] == 'true'
  SimpleCov.command_name 'test:unit'
  SimpleCov.coverage_dir 'tmp/coverage'
  SimpleCov.start('rails') do
    # we test seeds in a different way - just by running them
    add_filter '/lib/seeds/'
  end
end
