require 'integration_helper'

feature "Render the country select for the Rule modal", js: true do
  before do
    @user = login
    allow_any_instance_of(SiteElementSerializer).
      to receive(:proxied_url2png).and_return('')
  end

  it "sets the United States as the default country" do
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

    select('Country Code')
    value = find('#rule_conditions_attributes').value

    expect(value).to eql('US')
  end

  it "properly sets the value when the condition has been set previously" do
    site = @user.sites.first
    payment_method = create(:payment_method, user: @user)
    site.change_subscription(Subscription::Pro.new(schedule: 'monthly'), payment_method)
    rule = create(:rule)
    rule.conditions.create(segment: 'LocationCountryCondition', operand: 'is', value: 'AR')
    site.rules << rule
    element = create(:site_element, rule: site.rules.first)
    site.reload

    visit edit_site_site_element_path(site, element.id)

    page.find('a', text: 'Next').click
    page.find('a', text: 'Next').click
    page.find('a', text: 'Next').click
    page.find('a', text: 'Next').click
    page.find('a', text: 'Edit.').click

    select('Country Code')
    value = find('#rule_conditions_attributes').value

    expect(value).to eql('AR')
  end
end
