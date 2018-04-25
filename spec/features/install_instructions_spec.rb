require 'integration_helper'

feature 'Install Instructions', js: true do
  given(:user) { create :user, :with_site }
  given(:site) { user.sites.first }
  given(:terms_and_conditions_effective_date) { Date.parse(Settings.new_terms_and_conditions_effective_date) }

  background do
    sign_in user
  end

  scenario 'fetch install code' do
    visit site_install_path(site)
    find('.reveal-title', text: 'I can install code myself').click

    expect(page).to have_content(site.script_url)
  end

  context 'when user sign up before effective date' do
    given(:user) { create(:user, :with_site, created_at: terms_and_conditions_effective_date - 1.day) }

    scenario 'displays T&C updated message' do
      visit site_install_path(site)

      expect(page).to have_content('Please review our updated Terms of Use and Privacy Policy')
    end
  end

  context 'when user sign up after effective date' do
    given(:user) { create(:user, :with_site, created_at: terms_and_conditions_effective_date + 1.day) }

    scenario 'displays T&C updated message' do
      visit site_install_path(site)

      expect(page).not_to have_content('Please review our updated Terms of Use and Privacy Policy')
    end
  end
end
