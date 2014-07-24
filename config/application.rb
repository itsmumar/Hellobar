require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Hellobar
  class Application < Rails::Application
    config.autoload_paths += %W(#{config.root}/app/models/condition/)
    config.autoload_paths += %W(#{config.root}/app/models/validators)

    config.sass.preferred_syntax = :sass
    config.action_mailer.default_url_options = { host: "www.hellobar.com" }

    config.assets.precompile += %w( editor.css )
    config.assets.precompile += %w( editor/application.js )
    config.assets.paths << Rails.root.join('vendor', 'assets')

    config.handlebars.precompile = false
    config.handlebars.templates_root = 'editor/templates'
  end
end
