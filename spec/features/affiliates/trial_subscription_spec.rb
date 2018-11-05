describe 'Affiliate trial subscription', js: true do
  let(:user) { create(:user, :affiliate) }

  context 'when there is a partner record' do
    before do
      create(:partner, affiliate_identifier: user.affiliate_identifier, partner_plan_id: 'growth_90')
      sign_in user
    end

    it 'adds 90 days of trial on Growth subscription when user creates a site', freeze: '2018-06-24T14:00 UTC' do
      visit new_site_path

      fill_in 'site[url]', with: 'mysites.com'
      click_on 'Create Site'

      expect(page).to have_content 'I’ll do this later, take me to my dashboard'
      click_on 'I’ll do this later, take me to my dashboard'

      expect(page).to have_content 'Settings'
      click_on 'Settings'

      expect(page).to have_content 'Enter Payment Info'
      expect(page).to have_content 'Please enter credit card details by 2018-09-22'
    end
  end

  context 'when there is no partner record' do
    before do
      sign_in user
    end

    it 'adds 30 days of trial on Growth subscription when user creates a site', freeze: '2018-06-24T14:00 UTC' do
      visit new_site_path

      fill_in 'site[url]', with: 'mysites.com'
      click_on 'Create Site'

      expect(page).to have_content 'I’ll do this later, take me to my dashboard'
      click_on 'I’ll do this later, take me to my dashboard'

      expect(page).to have_content 'Settings'
      click_on 'Settings'

      expect(page).to have_content 'Enter Payment Info'
      expect(page).to have_content 'Please enter credit card details by 2018-07-24'
    end
  end
end
