require 'integration_helper'

feature 'Manage Settings', :js do
  before { stub_cyber_source :purchase }

  before do
    @user = login
    @site = @user.sites.first
    @rule = @site.create_default_rules

    credit_card = create(:credit_card, user: @user)
    ChangeSubscription.new(@site, { subscription: 'pro', schedule: 'monthly' }, credit_card).call

    visit edit_site_path(@site)
  end

  scenario 'it allows adding new custom invoice address' do
    page.find('a', text: 'Add custom invoice address').click

    fill_in 'site_invoice_information', with: 'my cool address'

    click_button('Save & Update')

    visit edit_site_path(@site)

    expect(page).to have_content('my cool address')
  end
end
