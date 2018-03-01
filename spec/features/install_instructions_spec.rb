require 'integration_helper'

feature 'Install Instructions', js: true do
  given(:user) { create :user, :with_site }
  given(:site) { user.sites.first }

  before do
    sign_in user
  end

  scenario 'fetch install code' do
    visit site_install_path(site)
    find('.reveal-title', text: 'I can install code myself').click

    expect(page).to have_content(site.script_url)
  end
end
