ServiceProviders::Provider.configure do |config|
  config.aweber.consumer_key = Settings.identity_providers['aweber']['consumer_key']
  config.aweber.consumer_secret = Settings.identity_providers['aweber']['consumer_secret']

  config.constantcontact.app_key = Settings.identity_providers['constantcontact']['app_key']

  config.maropost.url = Settings.identity_providers['maropost']['url']
end
