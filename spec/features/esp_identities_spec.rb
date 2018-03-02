require 'integration_helper'

feature 'App handles oauth error', :js do
  given(:user) { create :user, :with_site }
  given(:site) { user.sites.first }

  background do
    sign_in user
  end

  scenario 'and redirects to contact list ' do
    OmniAuth.config.mock_auth[:mailchimp] = :invalid_credentials

    visit new_site_identity_path(site, provider: 'mailchimp')

    expect(page).to have_content('invalid_credentials')

    OmniAuth.config.mock_auth[:mailchimp] = nil
  end
end
