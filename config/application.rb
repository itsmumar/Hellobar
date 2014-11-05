require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Hellobar
  class Application < Rails::Application
    config.autoload_paths += %W(#{config.root}/app/models/condition/)
    config.autoload_paths += %W(#{config.root}/app/models/validators)
    # We'd prefer to use initializers to load the files from the /lib
    # directory that we need. This way we have more control over load
    # order and have a convenient place to put other initialization 
    # code (config, etc.)
    # config.autoload_paths += %W(#{config.root}/lib)

    config.sass.preferred_syntax = :sass
    config.action_mailer.default_url_options = { host: "www.hellobar.com" }

    config.assets.precompile += ['editor.css', 'static.css', 'admin.css', 'editor/application.js', '*.css.erb', '*.css.sass.erb']
    config.assets.paths << Rails.root.join('vendor', 'assets')

    config.handlebars.precompile = false
    config.handlebars.templates_root = 'editor/templates'

    config.to_prepare do
        Devise::SessionsController.layout proc{ |controller| action_name == 'new' ? 'static' : 'application' }
    end
  end
end
