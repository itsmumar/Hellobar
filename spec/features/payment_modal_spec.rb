require 'integration_helper'

feature 'Payment modal interaction', :js do
  given(:user) { login }
  given(:site) { user.sites.first }
  given(:payment_method) { create(:payment_method, user: user) }

  context 'pro subscription' do
    before { stub_gateway_methods :purchase }

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
    before { stub_gateway_methods :update, :purchase }

    before do
      create :rule, site: site
      create(:subscription, :free, site: site, payment_method: payment_method)

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

      fill_payment_form
      page.find('.submit').click

      expect(page).to have_text "CONGRATULATIONS ON UPGRADING #{ site.normalized_url.upcase } TO THE PRO PLAN!"
      expect(page).to have_text 'Your card ending in 1111 has been charged $149.00.'
      expect(page).to have_text 'You will be billed $149.00 every year.'
      expect(page).to have_text 'Your next bill will be on Jun 20th, 2018.'

      page.find('a', text: 'OK').click
      expect(page).to have_content 'is on the Pro plan'
    end

    scenario 'trying to remove branding triggers the Pro Upgrade popup' do
      visit site_path(site)

      click_on 'Create New'

      find('.goal-block.contacts').click_on('Select This Goal')
      click_button 'Continue'
      find('.step-style').click
      find('.toggle-showing-branding .toggle-off').click

      expect(page).to have_content "Upgrade #{ site.normalized_url } to remove branding"
    end

    scenario 'trying to enable bar hiding triggers the Pro Upgrade popup' do
      visit site_path(site)

      click_on 'Create New'

      find('.goal-block.contacts').click_on('Select This Goal')
      click_button 'Continue'
      find('.step-style').click
      find('.toggle-hiding .toggle-on').click

      expect(page).to have_content "Upgrade #{ site.normalized_url } to allow hiding a bar"
    end

    def fill_payment_form
      form = create :payment_form
      fill_in 'payment_method_details[name]', with: form.name
      fill_in 'payment_method_details[number]', with: form.number
      fill_in 'payment_method_details[expiration]', with: form.expiration
      fill_in 'payment_method_details[verification_value]', with: form.verification_value
      fill_in 'payment_method_details[address]', with: form.address
      fill_in 'payment_method_details[city]', with: form.city
      fill_in 'payment_method_details[state]', with: form.state
      fill_in 'payment_method_details[zip]', with: form.zip
      select 'United States of America', match: :first, from: 'payment_method_details[country]'
    end
  end
end
