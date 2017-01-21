require 'integration_helper'
require 'service_provider_integration_helper'

feature "ConvertKit Integration", js: true do
  before do
    @fake_data_api_original = Hellobar::Settings[:fake_data_api]
    Hellobar::Settings[:fake_data_api] = true
    @user = login
  end

  after do
    Hellobar::Settings[:fake_data_api] = @fake_data_api_original
  end

  def connect_convert_kit
    site = @user.sites.create(url: random_uniq_url)
    contact_list = create(:contact_list, site: site)

    visit site_contact_list_path(site, contact_list)

    page.find("#edit-contact-list").click
    page.find("a", text: "Nevermind, I want to view all tools").click
    page.find(".convert_kit-provider").click

    fill_in 'contact_list[data][api_key]', with: 'OgSSj78Ql5mPI5AxH51li8kRhjvd9seZ_AnGmKZ_xlg'

    page.find(".button.ready").click
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
end
