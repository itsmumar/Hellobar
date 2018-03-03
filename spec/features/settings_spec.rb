require 'integration_helper'

feature 'Manage Settings', :js do
  given(:user) { create :user, :with_site }
  given(:site) { user.sites.first }
  given!(:rule) { site.create_default_rules }
  given(:credit_card) { create :credit_card, user: user }

  background do
    stub_cyber_source :purchase

    sign_in user

    ChangeSubscription.new(site, { subscription: 'pro', schedule: 'monthly' }, credit_card).call

    visit edit_site_path(site)
  end

  scenario 'it allows adding new custom invoice address' do
    page.find('a', text: 'Add custom invoice address').click

    fill_in 'site_invoice_information', with: 'my cool address'

    click_button('Save & Update')

    visit edit_site_path(site)

    expect(page).to have_content('my cool address')
  end
end
