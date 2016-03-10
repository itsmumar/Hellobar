require 'integration_helper'

feature "Connect to api ESP", js: true do
  before { @user = login }
  after { devise_reset }

  scenario "connect to Mad Mimi" do
    fake_data_api_original = Hellobar::Settings[:fake_data_api]
    Hellobar::Settings[:fake_data_api] = true

    site = @user.sites.create(url: random_uniq_url)
    contact_list = create(:contact_list, site: site)

    visit site_contact_list_path(site, contact_list)

    page.find("#edit-contact-list").click

    page.select 'Mad Mimi', :from => 'Where do you want your contacts stored?'

    fill_in 'contact_list[data][username]', with: 'tj+madmimitest@polymathic.me'
    fill_in 'contact_list[data][api_key]', with: '12225410b3e4b656e09ce7760bfaa240'

    page.find(".button.ready").click

    page.select 'TEST LIST', :from => 'Choose a Mad Mimi list to sync with'

    page.find(".button.submit").click

    expect(page).to have_content('Mad Mimi list "TEST LIST"')

    Hellobar::Settings[:fake_data_api] = fake_data_api_original
  end
end
