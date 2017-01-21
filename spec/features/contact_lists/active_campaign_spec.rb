require 'integration_helper'
require 'service_provider_integration_helper'

feature "ActiveCampaign Integration", js: true do
  before do
    @user = login
  end

  def connect_active_campaign
    site = @user.sites.create(url: random_uniq_url)
    contact_list = create(:contact_list, site: site)

    visit site_contact_list_path(site, contact_list)

    page.find("#edit-contact-list").click
    page.find("a", text: "Nevermind, I want to view all tools").click
    page.find(".active_campaign-provider").click

    fill_in 'contact_list[data][app_url]', with: 'hellobar.api-us1.com'
    fill_in 'contact_list[data][api_key]', with: 'dea2f200e17b9a3205f3353030b7d8ad55852aa3ccec6d7c4120482c8e8feb5fd527cff3'

    page.find(".button.ready").click
  end

  scenario "connecting to Active Campaign" do
    connect_active_campaign

    expect(page).to have_content('Choose a Active Campaign list to sync with')
  end

  scenario "select list" do
    connect_active_campaign
    selector = 'select#contact_list_remote_list_id'

    page.find(selector).select('HB List2')
    page.find('.button.submit').click

    page.find('#edit-contact-list').click

    expect(page).to have_content("HB List2")
  end
end
