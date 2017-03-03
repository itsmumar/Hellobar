require 'integration_helper'

feature 'Manage Bars', js: true do
  before do
    @user = login
    @site = @user.sites.first
    @rule = @site.create_default_rules
    allow_any_instance_of(Site).to receive(:lifetime_totals).and_return('1' => [[1, 0]])
  end

  context 'script is not installed' do
    before do
      allow_any_instance_of(Site).to receive(:has_script_installed?).and_return(false)
    end

    scenario 'shows install instructions if user has site elements' do
      create(:site_element, rule: @rule)

      visit site_site_elements_path(@site)
      expect(page).to have_content('Your Hello Bar has not been installed yet!')
    end

    scenario 'shows option for adding new bar when no bars exist' do
      visit site_site_elements_path(@site)
      expect(page).to have_content('Create a new Hello Bar')
    end
  end

  context 'script is installed' do
    before do
      allow_any_instance_of(Site).to receive(:has_script_installed?).and_return(true)
    end

    scenario 'shows option for adding new bar when no bars exist' do
      visit site_site_elements_path(@site)
      expect(page).to have_content('Create a new Hello Bar')
    end

    scenario 'shows option for a/b testing a bar when site elements exist' do
      create(:site_element, rule: @rule)

      visit site_site_elements_path(@site)
      wait_for_ajax
      expect(page).to have_content('A/B test a new bar for this rule')
    end
  end

  context 'user updates' do
    before { create(:site_element, rule: @rule) }

    it 'show update to old users' do
      @user.update_attributes(wordpress_user_id: 12_345)
      visit site_site_elements_path(@site)
      expect(page).to have_content('Where did all my views and conversions go')
    end

    it 'shouldnt show update to new users' do
      @user.update_attributes(wordpress_user_id: nil)
      visit site_site_elements_path(@site)
      expect(page).to_not have_content('Where did all my views and conversions go')
    end
  end
end
