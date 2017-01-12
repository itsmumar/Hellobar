require 'integration_helper'
require 'service_provider_integration_helper'

feature "Infusionsoft Integration", js: true do
  before do
    @fake_data_api_original = Hellobar::Settings[:fake_data_api]
    Hellobar::Settings[:fake_data_api] = true
    @user = login
  end

  after do
    # devise_reset
    Hellobar::Settings[:fake_data_api] = @fake_data_api_original
  end

  def connect_infusionsoft
    site = @user.sites.create(url: random_uniq_url)
    contact_list = create(:contact_list, site: site)

    visit site_contact_list_path(site, contact_list)

    page.find("#edit-contact-list").click
    page.find("a", text: "Nevermind, I want to view all tools").click
    page.find(".infusionsoft-provider").click
    # page.select 'Infusionsoft', from: 'Where do you want your contacts stored?'

    fill_in 'contact_list[data][app_url]', with: 'ft319.infusionsoft.com'
    fill_in 'contact_list[data][api_key]', with: '79f110f74f0db4767710ccec533347b0'

    page.find(".button.ready").click
  end

  scenario "connecting to Infusionsoft" do
    connect_infusionsoft

    expect(page).to have_content('Apply Tags (Optional)')
  end

  scenario "adding tags" do
    connect_infusionsoft

    page.all('select.contact-list-tag').first.select('Activist')

    page.find("a[data-js-action='add-tag']").click

    page.all('select.contact-list-tag').last.select('Extrovert')

    page.find('.button.submit').click

    page.find('#edit-contact-list').click

    expect(page).to have_content('Activist')
    expect(page).to have_content('Extrovert')
  end
end
