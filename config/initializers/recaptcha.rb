require './config/initializers/settings'

Recaptcha.configure do |config|
  config.public_key  = Hellobar::Settings[:recaptcha_public_key]
  config.private_key  = Hellobar::Settings[:recaptcha_private_key]
end
