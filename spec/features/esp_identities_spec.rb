require 'integration_helper'

feature 'App handles oauth error', js: true do
  before { @user = login }

  scenario 'and redirects to contact list ' do
    OmniAuth.config.mock_auth[:mailchimp] = :invalid_credentials

    site = create :site, user: @user

    visit new_site_identity_path(site, provider: 'mailchimp')

    expect(page).to have_content('invalid_credentials')
    OmniAuth.config.mock_auth[:mailchimp] = nil
  end
end
