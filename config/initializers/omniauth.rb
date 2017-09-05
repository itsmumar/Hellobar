# rename infusionsoft to not conflict with old provider
OmniAuth::Strategies::Infusionsoft.option :name, 'infusion_soft'

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :aweber, Settings.identity_providers['aweber']['consumer_key'], Settings.identity_providers['aweber']['consumer_secret']
  provider :constantcontact, Settings.identity_providers['constantcontact']['app_key'], Settings.identity_providers['constantcontact']['app_secret']
  provider :createsend, Settings.identity_providers['createsend']['client_id'], Settings.identity_providers['createsend']['secret'], scope: 'ManageLists,ImportSubscribers'
  provider :drip, Settings.identity_providers['drip']['client_id'], Settings.identity_providers['drip']['secret']
  provider :google_oauth2, Settings.google_auth_id, Settings.google_auth_secret
  provider :mailchimp, Settings.identity_providers['mailchimp']['client_id'], Settings.identity_providers['mailchimp']['secret']
  provider :verticalresponse, Settings.identity_providers['verticalresponse']['client_id'], Settings.identity_providers['verticalresponse']['secret']
  provider :infusionsoft, Settings.identity_providers['infusion_soft']['client_id'], Settings.identity_providers['infusion_soft']['secret']

  on_failure do |env|
    provider = env['omniauth.error.strategy'].try(:name)

    if provider.nil? || provider == 'google_oauth2'
      Users::OmniauthCallbacksController.action(:failure).call(env)
    else
      ContactListsController.action(:index).call(env)
    end
  end
end
