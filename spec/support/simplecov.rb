require 'simplecov'
SimpleCov.command_name 'test:unit'
SimpleCov.coverage_dir 'tmp/coverage'
SimpleCov.start('rails') do
  # we test seeds in a different way - just by running them
  add_filter '/lib/seeds/'
end
