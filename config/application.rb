require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Hellobar
  class Application < Rails::Application
    # Require Hellobar::Settings so that we can use them in this config file
    require File.join(Rails.root, 'config/initializers', 'settings.rb')

    # We'll handle our own errors
    config.exceptions_app = self.routes

    config.autoload_paths += Dir[Rails.root.join('app', 'models', '**/')]
    config.autoload_paths += %W(#{config.root}/lib/queue_worker/)
    # We'd prefer to use initializers to load the files from the /lib
    # directory that we need. This way we have more control over load
    # order and have a convenient place to put other initialization
    # code (config, etc.)
    # config.autoload_paths += %W(#{config.root}/lib)

    config.action_mailer.preview_path = "#{Rails.root}/spec/mailers/previews"

    config.sass.preferred_syntax = :sass
    config.action_mailer.default_url_options = { host: Hellobar::Settings[:host] }

    config.assets.precompile += ['editor.css', 'static.css', 'admin.css', 'editor/vendor.js', 'editor/application.js', 'ember.js', '*.css.erb', '*.css.sass.erb']
    config.assets.paths << Rails.root.join('vendor', 'assets')

    config.to_prepare do
      Devise::SessionsController.layout proc { |controller| action_name == 'new' ? 'static' : 'application' }
    end

    config.generators do |g|
      g.factory_girl false
    end
  end
end
