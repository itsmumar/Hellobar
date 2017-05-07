require 'integration_helper'
require 'service_provider_integration_helper'

feature 'ActiveCampaign Integration', :js, :vcr do
  let(:provider) { 'active_campaign' }

  before do
    allow(Settings).to receive(:fake_data_api).and_return true
    @user = login
  end

  context 'when invalid' do
    scenario 'displays error' do
      open_provider_form(@user, provider)
      fill_in 'contact_list[data][app_url]', with: 'hellobar.api-us1.com'
      fill_in 'contact_list[data][api_key]', with: 'invalid-key'

      page.find('.button.ready').click
      expect(page).to have_content('There was a problem connecting your Active Campaign account')
    end
  end

  context 'when valid' do
    scenario 'connecting to Active Campaign' do
      connect_active_campaign

      expect(page).to have_content('Choose a Active Campaign list to sync with')
    end

    scenario 'select list' do
      connect_active_campaign
      selector = 'select#contact_list_remote_list_id'

      page.find(selector).select('HB List2')
      page.find('.button.submit').click

      page.find('#edit-contact-list').click

      expect(page).to have_content('HB List2')
    end
  end

  private

  def connect_active_campaign
    open_provider_form(@user, provider)

    fill_in 'contact_list[data][app_url]', with: 'hellobar.api-us1.com'
    fill_in 'contact_list[data][api_key]', with: 'valid-active-campaign-key'

    page.find('.button.ready').click
  end
end
