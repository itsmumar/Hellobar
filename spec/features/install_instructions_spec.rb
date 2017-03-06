require 'integration_helper'

feature 'Install Instructions', js: true do
  before { @user = login }

  scenario 'fetch install code' do
    site = @user.sites.first
    visit site_install_path(site)
    find('.reveal-title', text: 'I can install code myself').click
    expect(page).to have_content(site.script_url)
  end
end
