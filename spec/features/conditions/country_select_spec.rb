require 'integration_helper'

feature 'Render the country select for the Rule modal', :js do
  extend FeatureHelper

  given(:user) { create :user, :with_site }
  given(:site) { user.sites.first }
  given(:credit_card) { create :credit_card, user: user }
  given(:custom_rule) { create :rule }

  background do
    stub_cyber_source :purchase

    sign_in user

    allow_any_instance_of(SiteElementSerializer)
      .to receive(:proxied_url2png).and_return('')

    stub_out_ab_variations('Targeting UI Variation 2016-06-13') { 'variant' }

    ChangeSubscription.new(site, { subscription: 'pro', schedule: 'monthly' }, credit_card).call
  end

  it 'sets the United States as the default country' do
    site.rules << custom_rule
    element = create(:site_element, rule: custom_rule)

    site.reload

    visit edit_site_site_element_path(site, element.id)
    bypass_setup_steps(3)

    page.find('a', text: 'Edit.').click
    page.find('a', text: '+').click

    select('Country')
    value = find('.location-country-select').value

    expect(value).to eql('US')
  end

  it 'properly sets the value when the condition has been set previously' do
    custom_rule.conditions.create(segment: 'LocationCountryCondition', operand: 'is', value: ['AR'])

    site.rules << custom_rule

    element = create(:site_element, rule: custom_rule)
    site.reload

    visit edit_site_site_element_path(site, element.id)
    bypass_setup_steps(3)

    expect(page).to have_content 'Geolocation Country is AR'

    page.find('a', text: 'Edit.').click

    expect(page).to have_content 'EDIT RULE'

    expect(find('.location-country-select').value).to eql('AR')
  end
end
