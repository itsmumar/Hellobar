require 'integration_helper'

feature 'Manage Settings', :js do
  before { stub_cyber_source :purchase }

  before do
    @user = login
    @site = @user.sites.first
    @rule = @site.create_default_rules

    allow_any_instance_of(Site).to receive(:lifetime_totals).and_return('1' => [[1, 0]])

    payment_method = create(:payment_method, user: @user)
    ChangeSubscription.new(@site, { plan: 'pro', schedule: 'monthly' }, payment_method).call

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
