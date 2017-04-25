require './config/initializers/settings'

Rails.application.config.roadie.url_options = { host: Hellobar::Settings[:host], scheme: 'https' }
