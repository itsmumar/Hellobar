require 'integration_helper'

feature 'Payment modal interaction', :js do
  given(:user) { login }
  given(:site) { user.sites.first }
  given(:payment_method) { create(:payment_method, user: user) }

  context 'pro subscription' do
    scenario "downgrade to free from pro should say when it's active until" do
      site.change_subscription(Subscription::Pro.new(schedule: 'monthly'), payment_method)

      end_date = site.current_subscription.active_until

      visit edit_site_path(site)

      click_link('Change plan or billing schedule')
      find('.different-plan').click
      basic_plan = find('.package-block.basic')
      basic_plan.find('.button').click

      expect(page).to have_content "until #{ end_date.strftime('%-m-%-d-%Y') }"
    end
  end

  context 'free subscription' do
    before do
      allow_any_instance_of(CyberSourceCreditCard::CyberSourceCreditCardValidator)
        .to receive(:validate).and_return(true)
      allow_any_instance_of(PaymentMethod).to receive(:pay).and_return(true)

      create :rule, site: site
      create(:free_subscription, site: site, payment_method: payment_method)

      allow_any_instance_of(SiteElementSerializer)
        .to receive(:proxied_url2png).and_return('')
      allow_any_instance_of(ApplicationController)
        .to receive(:ab_variation).and_return('original')
    end

    scenario 'upgrade to pro from free' do
      visit edit_site_path(site)

      page.find('footer .show-upgrade-modal').click
      pro_plan = page.find('.package-block.pro')
      pro_plan.find('.button').click

      page.find('.submit').click
      page.find('a', text: 'OK').click
      expect(page).to have_content 'is on the Pro plan'
    end

    scenario 'trying to remove branding triggers the Pro Upgrade popup' do
      visit site_path(site)

      click_on 'Create New'

      find('.goal-block[data-route="contacts"]').click_link 'Select This Goal'

      expect(page).to have_content 'GROW YOUR MAILING LIST'

      click_button 'Continue'

      click_on 'Style'

      click_on 'Bar'

      find('.toggle-showing-branding .toggle-off').click

      expect(page).to have_content "Upgrade #{ site.normalized_url } to remove branding"
    end

    scenario 'trying to enable bar hiding triggers the Pro Upgrade popup' do
      visit site_path(site)

      click_on 'Create New'

      find('.goal-block[data-route="contacts"]').click_link 'Select This Goal'

      expect(page).to have_content 'GROW YOUR MAILING LIST'

      click_button 'Continue'

      click_on 'Style'

      click_on 'Bar'

      find('.toggle-hiding .toggle-on').click

      expect(page).to have_content "Upgrade #{ site.normalized_url } to allow hiding a bar"
    end
  end
end
