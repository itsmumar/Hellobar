require 'integration_helper'

feature 'Users can use site element targeting rule presets', :js do
  given(:free_options)   { ['Everyone'] }
  given(:paid_options)   { ['Mobile Visitors', 'Homepage Visitors'] }
  given(:custom_option)  { 'Custom Rule' }
  given(:saved_option)   { 'Show to a saved targeting rule' }
  given(:site)           { @user.sites.first }

  before do
    @user = login

    site.create_default_rules

    allow_any_instance_of(SiteElementSerializer)
      .to receive(:proxied_url2png).and_return('')

    stub_out_ab_variations('Targeting UI Variation 2016-06-13') { 'variant' }
  end

  feature 'Free subscription sites' do
    before do
      visit new_site_site_element_path(site) + '/#/targeting?skip_interstitial=true'
    end

    scenario 'The user can select free options' do
      find('a', text: free_options.first).click
      expect(page).to have_content 'CHANGE TARGET AUDIENCE'
    end

    scenario 'The user is prompted to upgrade when clicking rule presets' do
      find('a', text: 'CHANGE TARGET AUDIENCE').click

      (paid_options << custom_option).each do |text|
        find('a', text: text).click

        expect(page).to have_content 'MONTHLY BILLING'

        find('.upgrade-account-modal .modal-block > .icon-close').click
      end
    end
  end

  feature 'Pro subscription sites' do
    given(:custom_rule)        { create(:rule) }
    given(:first_select_input) { first('select')['id'] }
    given(:default_option)     { 'Choose a saved rule...' }

    before do
      payment_method = create(:payment_method, :success, user: @user)
      site.change_subscription(Subscription::Pro.new(schedule: 'monthly'), payment_method)

      custom_rule.conditions.create(segment: 'LocationCountryCondition', operand: 'is', value: ['AR'])
      site.rules << custom_rule
    end

    scenario 'The user can select any rule preset' do
      visit new_site_site_element_path(@user.sites.first) + '/#/targeting?skip_interstitial=true'

      (free_options + paid_options).each do |text|
        find('a', text: text).click
        find('a', text: 'CHANGE TARGET AUDIENCE').click
      end

      # wait for the UI to load.
      sleep 0.2

      find('a.saved-rule').click
      find('a', text: 'CHANGE TARGET AUDIENCE').click

      find('h6', text: custom_option).click
      find('a', text: 'Cancel').click
    end

    scenario 'Custom rule presets are editable as saved rules' do
      visit new_site_site_element_path(@user.sites.first) + '/#/targeting?skip_interstitial=true'
      find('a', text: 'CHANGE TARGET AUDIENCE').click
      find('h6', text: custom_option).click
      find('a', text: '+').click
      fill_in 'rule_name', with: 'New Custom Rule'
      find('a', text: 'Save').click

      find('a', text: 'Edit.').click
      fill_in 'rule_name', with: 'Edited Custom Rule'
      find('a', text: 'Save').click

      expect(page).to have_content 'Edited Custom Rule'
    end

    feature 'Editing existing site elements' do
      given(:preset_rule) { site.rules.find { |r| r.name == 'Mobile Visitors' } }

      scenario 'With a preset rule' do
        element = create(:site_element, rule: preset_rule)
        visit edit_site_site_element_path(site, element.id) + '/#/targeting?skip_interstitial=true'

        expect(page).to have_content preset_rule.name
      end

      scenario 'With a custom rule' do
        element = create(:site_element, rule: custom_rule)
        visit edit_site_site_element_path(site, element.id) + '/#/targeting?skip_interstitial=true'

        expect(page).to have_content custom_rule.name

        find('a', text: 'Edit.').click

        value = find('.location-country-select').value
        expect(value).to eql('AR')
      end
    end
  end
end
