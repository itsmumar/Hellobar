require 'integration_helper'
require 'service_provider_integration_helper'

feature 'Infusionsoft Integration', :js, :vcr do
  let(:provider) { 'infusionsoft' }

  before do
    allow(Settings).to receive(:fake_data_api).and_return true

    @user = login
  end

  context 'when invalid' do
    scenario 'invalid form details' do
      open_provider_form(@user, provider)
      fill_in 'contact_list[data][app_url]', with: 'ft319.infusionsoft.com'
      fill_in 'contact_list[data][api_key]', with: 'invalid-key'

      page.find('.button.ready').click
      expect(page).to have_content('There was a problem connecting your Infusionsoft account')
    end
  end

  context 'when valid' do
    scenario 'connecting to Infusionsoft' do
      connect_infusionsoft

      expect(page).to have_content('Apply Tags (Optional)')
    end

    scenario 'adding tags' do
      connect_infusionsoft
      selector = 'select.contact-list-tag'

      page.find(selector).select('Activist')
      page.find("a[data-js-action='add-tag']").click
      page.all(selector).last.select('Extrovert')
      page.find('.button.submit').click

      page.find('#edit-contact-list').click

      page.assert_selector(selector, count: 2)
    end
  end

  private

  def connect_infusionsoft
    open_provider_form(@user, provider)

    fill_in 'contact_list[data][app_url]', with: 'ft319.infusionsoft.com'
    fill_in 'contact_list[data][api_key]', with: 'valid-infusionsoft-key'

    page.find('.button.ready').click
  end
end
