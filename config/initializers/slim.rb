require 'slim'

if Rails.env.development? || Rails.env.test?
  Slim::Engine.set_default_options pretty: true, sort_attrs: false
end
