require 'integration_helper'
require 'service_provider_integration_helper'

feature 'MadMimi Integration', js: true do
  let(:provider) { 'mad_mimi_api' }

  before do
    allow(Settings).to receive(:fake_data_api).and_return true

    @user = login
  end

  scenario 'invalid form details', :vcr do
    open_provider_form(@user, provider)
    fill_in 'contact_list[data][username]', with: 'invalid-uname'
    fill_in 'contact_list[data][api_key]',  with: 'invalid-key'

    page.find('.button.ready').click
    expect(page).to have_content('There was a problem connecting your MadMimi account')
  end
end
