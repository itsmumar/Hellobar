require 'integration_helper'
require 'service_provider_integration_helper'

feature 'GetResponse integration', :js, :vcr do
  let(:provider) { 'get_response_api' }
  let(:tag) { 'new_lead' }

  before do
    @fake_data_api_original = Hellobar::Settings[:fake_data_api]
    Hellobar::Settings[:fake_data_api] = true
    @user = login
  end

  after do
    Hellobar::Settings[:fake_data_api] = @fake_data_api_original
  end

  context 'when invalid form details' do
    scenario 'displays error' do
      open_provider_form(@user, provider)

      fill_in 'contact_list[data][api_key]', with: 'invalid-key'

      find('.button.ready').click
      expect(page).to have_content('There was a problem connecting your GetResponse account')
    end
  end

  context 'when valid' do
    scenario 'connecting to GetResponse, selecting a list and assigning a tag' do
      connect_to_provider

      expect(page).to have_content('Choose a GetResponse list to sync with')

      list_option = first('#contact_list_remote_list_id option').text
      select list_option, from: 'contact_list_remote_list_id'

      expect(page).to have_content('Apply Tags')

      tags_select = first('.contact-list-tag')
      tags_select.select tag

      find('.button.submit').click

      expect(page).to have_content 'Syncing contacts with GetResponse list'
    end
  end

  private

  def connect_to_provider
    open_provider_form(@user, provider)

    fill_in 'contact_list[data][api_key]', with: 'valid-key'

    find('.button.ready').click
  end
end
