feature 'Payment modal interaction', :js do
  given(:user) { create :user, :with_site }
  given(:site) { user.sites.first }
  given(:credit_card) { create :credit_card, user: user }

  background do
    sign_in user
  end

  context 'pro subscription' do
    background do
      stub_cyber_source :purchase
    end

    scenario "downgrade to free from pro should say when it's active until" do
      ChangeSubscription.new(site, { subscription: 'pro', schedule: 'monthly' }, credit_card).call

      end_date = site.current_subscription.active_until

      visit edit_site_path(site)

      click_link('Change plan or billing schedule')
      find('.different-plan').click
      sleep 2
      expect(page).to have_selector '.upgrade-account-modal'

      within '.package-block.basic' do
        find('.button', text: 'Choose Plan').click
      end
      expect(page).to have_content "until #{ end_date.strftime('%-m-%-d-%Y') }"
    end
  end

  context 'free subscription' do
    background do
      stub_cyber_source :store, :purchase

      create :rule, site: site
      create :subscription, :free, site: site, credit_card: credit_card

      allow_any_instance_of(SiteElementSerializer)
        .to receive(:proxied_url2png).and_return('')
      allow_any_instance_of(ApplicationController)
        .to receive(:ab_variation).and_return('original')
    end

    context 'before 2018-04-01', freeze: '2018-03-31T00:00 UTC' do
      scenario 'upgrade to pro from free' do
        visit edit_site_path(site)

        page.find('footer .show-upgrade-modal').click
        expect(page).to have_content "Upgrade #{ site.host }"

        within '.package-block.pro' do
          find('.button', text: 'Choose Plan').click
        end

        expect(page).to have_content 'Pro SELECT BILLING'
        expect(page.find('#anually-billing', visible: false)).to be_checked

        page.find('.submit').click

        expect(page).to have_text "CONGRATULATIONS ON UPGRADING #{ site.host.upcase } TO THE PRO PLAN!"
        expect(page).to have_text "Your card ending in #{ credit_card.last_digits } has been charged $149.00."
        expect(page).to have_text 'You will be billed $149.00 every year.'
        expect(page).to have_text "Your next bill will be on #{ date_format(1.year.from_now) }."

        page.find('a', text: 'OK').click
        expect(page).to have_content 'is on the Pro plan'
      end
    end

    context 'after 2018-04-01', freeze: '2018-04-01T00:00 UTC' do
      scenario 'upgrade to growth from free' do
        visit edit_site_path(site)

        page.find('footer .show-upgrade-modal').click
        within '.package-block.pro' do
          find('.button', text: 'Choose Plan').click
        end

        expect(page).to have_content 'Growth SELECT BILLING'
        expect(page.find('#anually-billing', visible: false)).to be_checked

        page.find('.submit').click

        expect(page).to have_text "CONGRATULATIONS ON UPGRADING #{ site.host.upcase } TO THE GROWTH PLAN!"
        expect(page).to have_text "Your card ending in #{ credit_card.last_digits } has been charged $289.00."
        expect(page).to have_text 'You will be billed $289.00 every year.'
        expect(page).to have_text "Your next bill will be on #{ date_format(1.year.from_now) }."

        page.find('a', text: 'OK').click
        expect(page).to have_content 'is on the Growth plan'
      end
    end

    scenario 'trying to remove branding triggers the Pro Upgrade popup' do
      visit site_path(site)

      click_on 'Create New'

      find('.goal-block.contacts').click_on('Select This Goal')
      click_button 'Continue'
      go_to_tab 'Settings'
      find('.toggle-showing-branding .toggle-on').click

      expect(page).to have_content "Upgrade #{ site.host } to remove branding"
    end

    scenario 'trying to enable bar hiding triggers the Pro Upgrade popup' do
      visit site_path(site)

      click_on 'Create New'

      find('.goal-block.contacts').click_on('Select This Goal')
      click_button 'Continue'
      go_to_tab 'Settings'
      find('.toggle-hiding .toggle-off').click

      expect(page).to have_content "Upgrade #{ site.host } to allow hiding a bar"
    end

    def date_format(date)
      date.strftime "%b #{ date.day.ordinalize }, %Y"
    end
  end
end
