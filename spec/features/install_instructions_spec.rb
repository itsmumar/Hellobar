feature 'Install Instructions', js: true do
  given(:user) { create :user, :with_site }
  given(:site) { user.sites.first }
  given(:terms_and_conditions_effective_date) { User::NEW_TERMS_AND_CONDITIONS_EFFECTIVE_DATE }

  background do
    sign_in user
  end

  scenario 'fetch install code' do
    visit site_install_path(site)
    find('.reveal-title', text: 'I can install code myself').click

    expect(page).to have_content(site.script_url)
  end

  scenario 'user does not see announcement message on install page when sign up without reference' do
    visit site_install_path(Site.last)

    expect(page).not_to have_content('Thanks for signing up! You’re currently on a free plan, in order to activate your 30 day trial of our Growth Plan')
  end

  context 'when user sign up before effective date' do
    given(:user) { create(:user, :with_site, created_at: terms_and_conditions_effective_date - 1.day) }

    scenario 'displays T&C updated message' do
      visit site_install_path(site)
      if Settings.tos_updated_display == true
        expect(page).to have_content('Please review our updated Terms of Use and Privacy Policy')
      else
        expect(page).not_to have_content('Please review our updated Terms of Use and Privacy Policy')
      end
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
