Rails.application.config.middleware.use OmniAuth::Builder do
  provider :mailchimp, Hellobar::Settings[:identity_providers][:mailchimp][:client_id], Hellobar::Settings[:identity_providers][:mailchimp][:secret]
  provider :createsend, Hellobar::Settings[:identity_providers][:createsend][:client_id], Hellobar::Settings[:identity_providers][:createsend][:secret], :scope => 'ManageLists,ImportSubscribers'
  provider :aweber, Hellobar::Settings[:identity_providers][:aweber][:consumer_key], Hellobar::Settings[:identity_providers][:aweber][:consumer_secret]
  provider :constantcontact, Hellobar::Settings[:identity_providers][:constantcontact][:app_key], Hellobar::Settings[:identity_providers][:constantcontact][:app_secret]
end
