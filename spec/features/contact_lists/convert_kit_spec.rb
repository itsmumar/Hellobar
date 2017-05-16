require 'integration_helper'
require 'service_provider_integration_helper'

feature 'ConvertKit integration', :js, :vcr do
  let(:provider) { 'convert_kit' }

  before do
    allow(Settings).to receive(:fake_data_api).and_return true
    @user = login
  end

  context 'when invalid' do
    scenario 'displays error' do
      open_provider_form(@user, provider)
      fill_in 'contact_list[data][api_key]', with: 'invalid-key'

      find('.button.ready').click
      expect(page).to have_content('There was a problem connecting your ConvertKit account')
    end
  end

  context 'when valid' do
    scenario 'connecting to Convert Kit and selecting a list' do
      connect_to_provider

      expect(page).to have_content('Choose a ConvertKit form to sync with')

      find('select#contact_list_remote_list_id').select('XO')
      find('.button.submit').click

      find('#edit-contact-list').click

      expect(page).to have_content('XO')
    end
  end

  private

  def connect_to_provider
    open_provider_form(@user, provider)

    fill_in 'contact_list[data][api_key]', with: 'valid-convertkit-key'

    find('.button.ready').click
  end
end
