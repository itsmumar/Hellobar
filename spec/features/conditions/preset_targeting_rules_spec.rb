require 'integration_helper'

feature "Users can use site element targeting rule presets", js: true do
  before do
    @user = login
    site.create_default_rules
    allow_any_instance_of(SiteElementSerializer).
      to receive(:proxied_url2png).and_return('')
    stub_out_get_ab_variations("Targeting UI Variation 2016-06-13") {"variant"}
  end
  let(:free_options)   { ["Everyone"] }
  let(:paid_options)   { ["Mobile Visitors", "Homepage Visitors"] }
  let(:custom_option)  { "Custom Rule" }
  let(:saved_option)   { "Show to a saved targeting rule" }
  let(:site)           { @user.sites.first }

  feature "Free subscription sites" do
    before do
      visit new_site_site_element_path(site, skip_interstitial: true, anchor: "targeting")
    end

    scenario "The user can select free options" do
      page.find('a', text: free_options.first).click
      expect(page).to have_content 'CHANGE TARGET AUDIENCE'
    end

    scenario "The user is prompted to upgrade when clicking rule presets" do
      (paid_options << custom_option).each do |text|
        page.find('a', text: text).click
        expect(page).to have_content 'MONTHLY BILLING'
        page.find(".upgrade-account-modal .icon-close").click
      end
    end
  end

  feature "Pro subscription sites" do
    let(:custom_rule)        { create(:rule) }
    let(:first_select_input) { page.first("select")["id"] }
    let(:default_option)     { "Choose a saved rule..." }

    before do
      payment_method = create(:payment_method, user: @user)
      site.change_subscription(Subscription::Pro.new(schedule: 'monthly'), payment_method)

      custom_rule.conditions.create(segment: 'LocationCountryCondition', operand: 'is', value: 'AR')
      site.rules << custom_rule
    end

    scenario "The user can select any rule preset" do
      visit new_site_site_element_path(@user.sites.first, skip_interstitial: true, anchor: "targeting")

      (free_options + paid_options).each do |text|
        page.find('a', text: text).click
        page.find('a', text: 'CHANGE TARGET AUDIENCE').click
      end

      page.find('a', text: saved_option).click
      expect(page).to have_select(first_select_input, :options => [default_option, custom_rule.name], :selected => default_option)
      page.find('a', text: 'CHANGE TARGET AUDIENCE').click

      page.find('a', text: custom_option).click
      page.find('a', text: 'Cancel').click
    end

    scenario "Custom rule presets are editable as saved rules" do
      visit new_site_site_element_path(@user.sites.first, skip_interstitial: true, anchor: "targeting")
      page.find('a', text: custom_option).click
      page.find('a', text: '+').click
      fill_in "rule_name", with: "New Custom Rule"
      page.find('a', text: 'Save').click

      expect(page).to have_content "New Custom Rule"
      expect(page).to have_select(first_select_input, :selected => "New Custom Rule")
      page.find('a', text: 'Edit.').click
      fill_in "rule_name", with: "Edited Custom Rule"
      page.find('a', text: 'Save').click

      expect(page).to have_content "Edited Custom Rule"
      expect(page).to have_select(first_select_input, :selected => "Edited Custom Rule")
    end

    feature "Editing existing site elements" do
      let(:preset_rule) { site.rules.find{|r| r.name == "Mobile Visitors"} }

      scenario "With a preset rule" do
        element = create(:site_element, rule: preset_rule)
        visit edit_site_site_element_path(site, element.id, skip_interstitial: true, anchor: "targeting")

        expect(page).to have_content preset_rule.name
      end

      scenario "With a custom rule" do
        element = create(:site_element, rule: custom_rule)
        visit edit_site_site_element_path(site, element.id, skip_interstitial: true, anchor: "targeting")

        expect(page).to have_content custom_rule.name
        expect(page).to have_select(first_select_input, :selected => custom_rule.name)

        page.find('a', text: 'Edit.').click

        value = find('#rule_conditions_attributes').value
        expect(value).to eql('AR')
      end
    end
  end
end
