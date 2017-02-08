require 'integration_helper'
require 'service_provider_integration_helper'

feature "MadMimi Integration", js: true do
  let(:provider) { 'mad_mimi_api' }

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
    fill_in 'contact_list[data][username]', with: 'invalid-uname'
    fill_in 'contact_list[data][api_key]',  with: 'invalid-key'

    page.find(".button.ready").click
    expect(page).to have_content('There was a problem connecting your MadMimi account')
  end
end
