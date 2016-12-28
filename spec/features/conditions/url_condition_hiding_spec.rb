require 'integration_helper'

feature "Hide the URL Condition from the Rule Modal", :js do
  extend FeatureHelper

  before do
    @user = login
    allow_any_instance_of(SiteElementSerializer).
      to receive(:proxied_url2png).and_return('')
    stub_out_get_ab_variations("Targeting UI Variation 2016-06-13") {"variant"}
  end

  it "hides the UrlCondition if the site doesn't already have it as a rule" do
    site = @user.sites.first
    payment_method = create(:payment_method, user: @user)
    site.change_subscription(Subscription::Pro.new(schedule: 'monthly'), payment_method)
    custom_rule = create(:rule)
    site.rules << custom_rule
    element = create(:site_element, rule: custom_rule)
    site.reload

    visit edit_site_site_element_path(site, element.id)
    bypass_setup_steps(4)

    page.find('a', text: 'Edit.').click
    page.find('a', text: '+').click

    expect(page).to have_content("URL")
    expect(page.has_css?('select.condition-segment > option[value="UrlCondition"]')).to eq(false)
  end

  it "shows the UrlCondition if the site already has it as a rule" do
    site = @user.sites.first
    payment_method = create(:payment_method, user: @user)
    site.change_subscription(Subscription::Pro.new(schedule: 'monthly'), payment_method)
    rule = create(:rule)
    rule.conditions.create segment: "UrlCondition", operand: "is", value: ["http://www.whatever.com"]
    site.rules << rule

    element = create(:site_element, rule: rule)
    site.reload

    visit edit_site_site_element_path(site, element.id)
    bypass_setup_steps(4)

    page.find('a', text: 'Edit.').click

    expect(page).to have_content("URL")
    expect(page.has_css?('select.condition-segment > option[value="UrlCondition"]')).to eq(true)
  end
end
