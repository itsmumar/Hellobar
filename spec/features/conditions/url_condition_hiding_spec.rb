require 'integration_helper'

feature "Hide the URL Condition from the Rule Modal", js: true do
  before do
    @user = login
    allow_any_instance_of(SiteElementSerializer).
      to receive(:proxied_url2png).and_return('')
  end

  it "hides the UrlCondition if the site doesnt already have it as a rule" do
    site = @user.sites.first
    payment_method = create(:payment_method, user: @user)
    site.change_subscription(Subscription::Pro.new(schedule: 'monthly'), payment_method)
    site.rules << create(:rule)
    element = create(:site_element, rule: site.rules.first)
    site.reload

    visit edit_site_site_element_path(site, element.id)

    page.find('a', text: 'Next').click
    page.find('a', text: 'Next').click
    page.find('a', text: 'Next').click
    page.find('a', text: 'Next').click
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

    element = create(:site_element, rule: site.rules.first)
    site.reload

    visit edit_site_site_element_path(site, element.id)

    page.find('a', text: 'Next').click
    page.find('a', text: 'Next').click
    page.find('a', text: 'Next').click
    page.find('a', text: 'Next').click
    page.find('a', text: 'Edit.').click

    expect(page).to have_content("URL")
    expect(page.has_css?('select.condition-segment > option[value="UrlCondition"]')).to eq(true)
  end
end
