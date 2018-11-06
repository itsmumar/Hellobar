feature 'Trial User', :js do
  given(:user) { create :user, :with_site }
  given(:site) { user.sites.first }
  given(:credit_card) { create :credit_card, user: user }

  context 'with credit card not registered' do
    before do
      AddTrialSubscription.new(site, subscription: 'pro', trial_period: '90').call

      sign_in user
      visit site_path(site)
    end

    scenario 'shows a button in the header that prompts user to enter payment' do
      expect(page).to have_content('Enter Payment Info')
    end

    scenario 'allows users to downgrade' do
      allow_any_instance_of(Subscription::Pro).to receive(:problem_with_payment?).and_return(true)
      allow_any_instance_of(Site).to receive(:script_installed?).and_return(true)
      visit site_path(site)
      expect(page).to have_content('Your subscription has not been renewed')
      find('.show-downgrade-modal').click

      sleep 1
      click_link('Downgrade')

      expect(site.reload.current_subscription).to be_a(Subscription::Free)

      Timecop.travel(91.days.from_now) do
        visit site_path(site)
        expect(page).to have_content('Upgrade Now')
      end
    end
  end

  context 'with credit card registered' do
    before do
      AddTrialSubscription.new(site, subscription: 'pro', trial_period: '90').call(credit_card)

      sign_in user
      visit site_path(site)
    end

    scenario 'does not show a button in the header that prompts user to enter payment' do
      expect(page).to_not have_content('Enter Payment Info')
    end
  end

  context 'shows warning banner' do
    before do
      AddTrialSubscription.new(site, subscription: 'pro', trial_period: '6').call

      sign_in user
    end

    scenario 'when less than 7 trial days remaining' do
      visit site_path(site)
      expect(page).to have_content('You\'ve got less than 7 days left!')
    end

    scenario 'when trial expired' do
      Timecop.travel(7.days.from_now) do
        visit site_path(site)
        expect(page).to have_content('Your free trial of our Growth Plan has expired')
      end
    end
  end
end
