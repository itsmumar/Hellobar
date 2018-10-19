feature 'Payment modal interaction', :js do
  given(:user) { create :user, :with_site }
  given(:site) { user.sites.first }
  given(:credit_card) { create :credit_card, user: user }

  background do
    sign_in user
  end

  context 'free subscription' do
    background do
      stub_cyber_source :store, :purchase
      stub_handle_overage(site, 100, 99)

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

        page.find('.show-upgrade-modal', match: :first).click
        expect(page).to have_content 'To unlock the next level'

        page.all('.button', text: 'Choose Plan')[1].click

        expect(page).to have_content 'Add new credit card'
        expect(page.find('#monthly-billing', visible: false)).to be_checked

        page.find('.submit').click

        expect(page).to have_text "CONGRATULATIONS ON UPGRADING #{ site.host.upcase } TO THE PRO PLAN!"
        expect(page).to have_text "Your card ending in #{ credit_card.last_digits } has been charged $29.00."
        expect(page).to have_text 'You will be billed $29.00 every month.'

        page.find('a', text: 'OK').click
        expect(page).to have_content 'is on the Pro plan'
      end
    end

    context 'after 2018-04-01', freeze: '2018-04-01T00:00 UTC' do
      scenario 'upgrade to growth from free' do
        visit edit_site_path(site)

        page.find('.show-upgrade-modal', match: :first).click
        page.all('.button', text: 'Choose Plan')[1].click

        expect(page).to have_content 'Growth'
        expect(page.find('#monthly-billing', visible: false)).to be_checked

        page.find('.submit').click

        expect(page).to have_text "CONGRATULATIONS ON UPGRADING #{ site.host.upcase } TO THE GROWTH PLAN!"
        expect(page).to have_text "Your card ending in #{ credit_card.last_digits } has been charged $29.00."
        expect(page).to have_text 'You will be billed $29.00 every month.'

        page.find('a', text: 'OK').click
        expect(page).to have_content 'is on the Growth plan'
      end
    end

    scenario 'trying to remove branding triggers the Pro Upgrade popup' do
      visit site_path(site)

      click_on 'Create New'

      find('.goal-block.contacts').click
      find('.goal-block.contacts').click
      go_to_tab 'Settings'
      find('.toggle-showing-branding .toggle-on').click

      expect(page).to have_content "To remove Hello Bar logo, upgrade your subscription for #{ site.host }"
    end

    scenario 'trying to ask leading questions triggers the Pro Upgrade popup' do
      visit site_path(site)

      click_on 'Create New'

      find('.goal-block.contacts').click
      find('.goal-block.contacts').click
      go_to_tab 'Design'
      find('.collapse', text: 'Leading Question').click
      find('.questions .toggle-switch').click

      expect(page).to have_content "To enable Yes/No Questions, upgrade your subscription for #{ site.host }"
    end

    def date_format(date)
      date.strftime "%b #{ date.day.ordinalize }, %Y"
    end
  end
end
