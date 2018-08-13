feature 'Render the country select for the Rule modal', :js do
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
    go_to_tab 'Targeting'

    find('a', text: 'Create new customer targeting rule').click
    fill_in 'rule_name', with: 'New Custom Rule'
    page.find('a', text: '+').click

    select('Country')
    value = find('.location-country-select').value

    expect(value).to eql('US')
  end
end
