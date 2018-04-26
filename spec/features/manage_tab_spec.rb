feature 'Manage Bars', js: true do
  given(:user) { create :user, :with_site }
  given(:site) { user.sites.first }
  given!(:rule) { site.create_default_rules }

  before do
    sign_in user

    allow_any_instance_of(Site).to receive(:statistics)
  end

  context 'script is not installed' do
    before do
      allow_any_instance_of(Site).to receive(:script_installed?).and_return(false)
    end

    scenario 'shows install instructions if user has site elements' do
      create(:site_element, rule: rule)

      visit site_site_elements_path(site)

      expect(page).to have_content('Your Hello Bar has not been installed yet!')
    end

    scenario 'shows option for adding new bar when no bars exist' do
      visit site_site_elements_path(site)

      expect(page).to have_content('Create a new Hello Bar')
    end
  end

  context 'script is installed' do
    before do
      site.update script_installed_at: Time.current
    end

    scenario 'shows option for adding a new bar when no bars exist' do
      visit site_site_elements_path(site)

      expect(page).to have_content('Create a new Hello Bar')
    end

    scenario 'shows option for a/b testing a bar when site elements exist' do
      create(:site_element, rule: rule)

      visit site_site_elements_path(site)

      wait_for_ajax

      expect(page).to have_content('A/B test a new bar for this rule')
    end
  end
end
