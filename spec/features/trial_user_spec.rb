require 'integration_helper'

feature 'Trial User', :js do
  given(:user) { create :user, :with_site }
  given(:site) { user.sites.first }

  background do
    AddTrialSubscription.new(site, subscription: 'pro', trial_period: '90').call

    sign_in user
  end

  scenario 'shows a button in the header that prompts user to enter payment' do
    visit site_path(site)
    expect(page).to have_content('Enjoying Hello Bar Pro?')
  end

  scenario 'allows users to downgrade' do
    allow_any_instance_of(Subscription::Pro).to receive(:problem_with_payment?).and_return(true)
    allow_any_instance_of(Site).to receive(:script_installed?).and_return(true)
    visit site_path(site)
    expect(page).to have_content('Your subscription has not been renewed')
    find('.show-downgrade-modal').click

    sleep 1
    click_link('Downgrade')

    expect(page).to have_content('90 days left of Pro features')
    expect(site.reload.current_subscription).to be_a(Subscription::Free)

    Timecop.travel(91.days.from_now) do
      visit site_path(site)
      expect(page).to have_content('Want More Power?')
    end
  end
end
