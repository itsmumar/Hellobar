# Read more about Teaspoon configuration: https://github.com/modeset/teaspoon/wiki/Teaspoon-Configuration

require 'teaspoon/jasmine/framework'
Teaspoon::Jasmine::Framework.register_version '2.6', 'jasmine/2.6.js', dependencies: ['teaspoon-jasmine2.js']

Teaspoon.configure do |config|
  config.mount_at = '/teaspoon'
  config.root = nil
  config.asset_paths = ['spec/javascripts', 'spec/javascripts/stylesheets']
  config.fixture_paths = ['spec/javascripts/fixtures']

  # SUITES
  #
  # To run a specific suite
  # - in the browser: http://localhost/teaspoon/[suite_name]
  # - with the rake task: rake teaspoon suite=[suite_name]
  # - with the cli: teaspoon --suite=[suite_name]

  # Default suite
  config.suite do |suite|
    suite.use_framework :jasmine, '2.6'
    suite.helper = 'spec_helper'
    suite.boot_partial = 'boot'
    suite.body_partial = 'body'
  end

  # Generator suite includes everything related to generated hellobar used by end-users
  config.suite :generator do |suite|
    suite.matcher = 'spec/javascripts/hellobar_generator/**/*_spec.{js,js.coffee,coffee}'
  end

  # Project suite includes everything related to hellobar.com project, except for scripts generation
  config.suite :project do |suite|
    suite.matcher = 'spec/javascripts/hellobar_project/**/*_spec.{js,js.coffee,coffee}'
  end

  # CONSOLE RUNNER SPECIFIC

  # Available: :dot, :clean, :documentation, :json, :junit, :pride, :rspec_html, :snowday, :swayze_or_oprah, :tap, :tap_y, :teamcity
  config.formatters = [:dot]
  config.color = true
  config.suppress_log = false

  # COVERAGE REPORTS / THRESHOLD ASSERTIONS
  #
  # Coverage reports requires Istanbul (https://github.com/gotwarlost/istanbul) to add instrumentation to your code and
  # display coverage statistics.
  #
  # To run with a specific coverage configuration
  # - with the rake task: rake teaspoon USE_COVERAGE=[coverage_name]
  # - with the cli: teaspoon --coverage=[coverage_name]

  config.use_coverage = false # not use coverage by default unless it's set up on CircleCI

  # coverage of the "Generator" segment; includes `hellobar.base.js` and `site_elements`
  # files in `vendor/assets/javascripts/` directory
  config.coverage :generator do |coverage|
    # Available: text-summary, text, html, lcov, lcovonly, cobertura, teamcity
    coverage.reports = ['text-summary', 'html']
    coverage.output_path = 'tmp/teaspoon'

    coverage.ignore = [
      %r{/lib/ruby/gems/},
      %r{/spec/javascripts/spec_helper.coffee},
      # exclude all vendor assets except for hellobar.base and site_elements subfolder - they are covered with tests
      %r{/vendor/assets/(?!javascripts/(hellobar|site_elements))},
      # exclude project's javascripts to focus only on generated code
      %r{/app/assets/javascripts/}
    ]
  end

  # coverage of the "Project" segment; includes `assets/javascripts/` files
  config.coverage :project do |coverage|
    # Available: text-summary, text, html, lcov, lcovonly, cobertura, teamcity
    coverage.reports = ['text-summary', 'html']
    coverage.output_path = 'tmp/teaspoon'

    coverage.ignore = [
      %r{/lib/ruby/gems/},
      %r{/spec/javascripts/spec_helper.coffee},
      %r{/vendor/assets/}
    ]
  end
end
