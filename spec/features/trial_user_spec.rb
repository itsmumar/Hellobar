require 'integration_helper'

feature 'Trial User', js: true do
  before do
    @user = login
    @site = create(:site)
    @site.users << @user
    AddTrialSubscription.new(@site, subscription: 'pro', trial_period: '90').call # 90 day trial subscription
  end

  scenario 'shows a button in the header that prompts user to enter payment' do
    visit site_path(@site)
    expect(page).to have_content('Enjoying Hello Bar Pro?')
  end

  scenario 'allows users to downgrade' do
    allow_any_instance_of(Subscription::Pro).to receive(:problem_with_payment?).and_return(true)
    allow_any_instance_of(Site).to receive(:script_installed?).and_return(true)
    visit site_path(@site)
    expect(page).to have_content('Your subscription has not been renewed')
    find('.show-downgrade-modal').click
    click_link('Downgrade')

    expect(page).to have_content('Want More Power?')
    expect(@site.reload.current_subscription).to be_a(Subscription::Free)
  end
end
