require 'slim'

Slim::Engine.set_options pretty: true, sort_attrs: false if Rails.env.development? || Rails.env.test?
