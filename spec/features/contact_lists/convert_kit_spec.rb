require 'integration_helper'
require 'service_provider_integration_helper'

feature "ConvertKit Integration", js: true do
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

    page.find(".button.ready").click
    expect(page).to have_content('There was a problem connecting your ConvertKit account')
  end

  scenario "connecting to Active Campaign" do
    connect_convert_kit

    expect(page).to have_content('Choose a ConvertKit form to sync with')
  end

  scenario "select list" do
    connect_convert_kit

    page.find('select#contact_list_remote_list_id').select('XO')
    page.find('.button.submit').click

    page.find('#edit-contact-list').click

    expect(page).to have_content("XO")
  end

  private
  def connect_convert_kit
    open_provider_form(@user, provider)
    fill_in 'contact_list[data][api_key]', with: 'valid-convertkit-key'

    page.find(".button.ready").click
  end
end
