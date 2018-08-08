feature 'Users can use site element targeting rule presets', :js do
  given(:free_options) { ['Everyone'] }
  given(:paid_options) { ['Mobile Visitors', 'Homepage Visitors'] }
  given(:saved_option) { 'Show to a saved targeting rule' }

  background do
    allow_any_instance_of(SiteElementSerializer)
      .to receive(:proxied_url2png).and_return('')

    stub_out_ab_variations('Targeting UI Variation 2016-06-13') { 'variant' }
  end

  context 'Free subscription sites' do
    given!(:user) { create :user, :with_site }
    given(:site) { user.sites.first }

    background do
      sign_in user

      site.create_default_rules

        visit new_site_site_element_path(site) + '/#/goal?skip_interstitial=true'
      find('h6', text: 'Collect emails').click
      go_to_tab 'Targeting'
    end

    scenario 'The user can select free options' do
      choose_rule free_options.first
      expect_choosen free_options.first
    end

    scenario 'The user is prompted to upgrade when clicking rule presets' do
      paid_options.each do |rule|
        choose_rule rule

        expect(page).to have_content 'MONTHLY BILLING'

        find('.upgrade-account-modal .modal-block > .icon-close').click
      end
    end
  end

  context 'Pro subscription sites' do
    given(:site) { create :site, :with_user, :pro }
    given(:user) { site.owners.last }
    given(:custom_rule) { create(:rule) }
    given(:credit_card) { create(:credit_card, user: user) }

    background do
      # sign_in user
      login_as user, scope: :user, run_callbacks: false

      site.create_default_rules

      custom_rule.conditions.create(segment: 'LocationCountryCondition', operand: 'is', value: ['AR'])

      site.rules << custom_rule

      visit new_site_site_element_path(site) + '/#/goal?skip_interstitial=true'
      find('h6', text: 'Collect emails').click
      go_to_tab 'Targeting'
    end

    scenario 'The user can select any rule preset' do
      (free_options + paid_options).each do |rule|
        choose_rule rule
        expect_choosen rule
      end
    end

    scenario 'Custom rule presets are editable as saved rules' do
      find('.actions a').click
      fill_in 'rule_name', with: 'New Custom Rule'
      find('a.button', text: 'Save').click
      expect_choosen 'New Custom Rule'
    end

    feature 'Editing existing site elements' do
      given(:preset_rule) { site.rules.find { |r| r.name == 'Mobile Visitors' } }

      scenario 'With a preset rule' do
        element = create(:site_element, rule: preset_rule)

        visit edit_site_site_element_path(site, element.id) + '/#/goal?skip_interstitial=true'
        find('h6', text: 'Collect emails').click
        go_to_tab 'Targeting'

        expect(page).to have_content preset_rule.name
      end

      scenario 'With a custom rule' do
        element = create(:site_element, rule: custom_rule)
        visit edit_site_site_element_path(site, element.id) + '/#/goal?skip_interstitial=true'
        find('h6', text: 'Collect emails').click
        go_to_tab 'Targeting'

        expect_choosen custom_rule.name
      end
    end
  end

  def choose_rule(rule)
    find('.select-wrapper.rules').click
    find('.ember-power-select-option', text: rule).click
  end

  def expect_choosen(rule)
    expect(find('.select-wrapper.rules .ember-power-select-selected-item').text).to eql rule
  end
end
