Rails.application.config.middleware.use OmniAuth::Builder do
  provider :mailchimp, Hellobar::Settings[:identity_providers][:mailchimp][:client_id], Hellobar::Settings[:identity_providers][:mailchimp][:secret]
  provider :createsend, Hellobar::Settings[:identity_providers][:createsend][:client_id], Hellobar::Settings[:identity_providers][:createsend][:secret], :scope => 'ManageLists,ImportSubscribers'
  provider :aweber, Hellobar::Settings[:identity_providers][:aweber][:consumer_key], Hellobar::Settings[:identity_providers][:aweber][:consumer_secret]
  provider :constantcontact, Hellobar::Settings[:identity_providers][:constantcontact][:app_key], Hellobar::Settings[:identity_providers][:constantcontact][:app_secret]
  provider :drip, Hellobar::Settings[:identity_providers][:drip][:client_id], Hellobar::Settings[:identity_providers][:drip][:secret]
  provider :google_oauth2, Hellobar::Settings[:google_auth_id], Hellobar::Settings[:google_auth_secret], access_type: 'offline', scope: 'email, profile, analytics.readonly'
  provider :verticalresponse, Hellobar::Settings[:identity_providers][:verticalresponse][:client_id], Hellobar::Settings[:identity_providers][:verticalresponse][:secret]

  on_failure do |env|
    provider = env['omniauth.error.strategy'].try(:name)
    if provider.nil? || provider == 'google_oauth2'
      Users::OmniauthCallbacksController.action(:failure).call(env)
    else
      ContactListsController.action(:index).call(env)
    end
  end
end
