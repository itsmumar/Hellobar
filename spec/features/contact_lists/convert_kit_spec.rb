require 'integration_helper'
require 'service_provider_integration_helper'

feature "ConvertKit integration", :js do
  let(:provider) { 'convert_kit' }

  before do
    @fake_data_api_original = Hellobar::Settings[:fake_data_api]
    Hellobar::Settings[:fake_data_api] = true
    @user = login
  end

  after do
    Hellobar::Settings[:fake_data_api] = @fake_data_api_original
  end

  scenario "invalid form details" do
    open_provider_form(@user, provider)
    fill_in 'contact_list[data][api_key]', with: 'invalid-key'

    find(".button.ready").click
    expect(page).to have_content('There was a problem connecting your ConvertKit account')
  end

  scenario "connecting to Convert Kit and selecting a list" do
    connect_to_provider

    expect(page).to have_content('Choose a ConvertKit form to sync with')

    find('select#contact_list_remote_list_id').select('XO')
    find('.button.submit').click

    find('#edit-contact-list').click

    expect(page).to have_content("XO")
  end

  private

  def connect_to_provider
    open_provider_form(@user, provider)

    fill_in 'contact_list[data][api_key]', with: 'valid-convertkit-key'

    find(".button.ready").click
  end
end
