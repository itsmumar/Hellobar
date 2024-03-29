# Make '#singularize' available here in the Guardfile
require 'active_support/core_ext/string'

# Only watch a subset of directories
directories %w[app config lib spec vendor]

# Explicitly ignore directories watched by Ember
ignore(/editor/, /public/, /app\/assets\/editor\/editor/)

# This group allows to skip running RuboCop when RSpec failed
group :red_green_refactor, halt_on_fail: true do
  guard :rspec, cmd: 'rspec -f doc', failed_mode: :focus do
    require 'guard/rspec/dsl'
    dsl = Guard::RSpec::Dsl.new(self)

    # RSpec files
    rspec = dsl.rspec
    watch(rspec.spec_support) { rspec.spec_dir }
    watch(rspec.spec_files)

    # Ruby files
    ruby = dsl.ruby
    dsl.watch_spec_files_for(ruby.lib_files)

    # Rails files
    rails = dsl.rails(view_extensions: %w[erb slim])
    dsl.watch_spec_files_for(rails.app_files)
    dsl.watch_spec_files_for(rails.views)

    watch(rails.controllers) do |m|
      [
        rspec.spec.call("controllers/#{ m[1] }_controller"),
        rspec.spec.call("requests/#{ m[1] }")
      ]
    end

    # Rails config changes
    watch(rails.app_controller)  { "#{ rspec.spec_dir }/controllers" }

    # Capybara features specs
    watch(rails.view_dirs)     { |m| rspec.spec.call("features/#{ m[1] }") }
    watch(rails.layouts)       { |m| rspec.spec.call("features/#{ m[1] }") }
    watch(%r{^spec/factories/(.+)\.rb$}) do |m|
      [
        "spec/models/#{ m[1].singularize }_spec.rb",
        "spec/controllers/#{ m[1] }_controller_spec.rb",
        "spec/requests/#{ m[1] }_controller_spec.rb"
      ]
    end
  end

  guard :rubocop, all_on_start: false do
    watch(/.+\.rb$/)
    watch(%r{(?:.+/)?\.rubocop\.yml$}) { |m| File.dirname(m[0]) }
  end
end

guard :shell do
  # Restart local webserver
  watch(%r{^lib/.*})                          { `touch tmp/restart.txt` }
  watch('config/environments/development.rb') { `touch tmp/restart.txt` }
  watch('config/secrets.yml')                 { `touch tmp/restart.txt` }
  watch(%r{^config/initializers/.+\.rb$})     { `touch tmp/restart.txt` }
end
