require Rails.root.join('config', 'initializers', 'settings.rb')

Rails.application.config.roadie.url_options = { host: Hellobar::Settings[:host], scheme: 'https' }
