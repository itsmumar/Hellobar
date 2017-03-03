require 'integration_helper'

feature 'Connect to api ESP', js: true do
  before { @user = login }

  #----------  MadMimi - Original  ----------#

  scenario 'connect to MadMimi - original email integration UI' do
    fake_data_api_original = Hellobar::Settings[:fake_data_api]
    Hellobar::Settings[:fake_data_api] = true

    site = @user.sites.create(url: random_uniq_url)
    contact_list = create(:contact_list, site: site)

    visit site_contact_list_path(site, contact_list)

    find('#edit-contact-list').click
    find('a', text: 'Nevermind, I want to view all tools').click
    find('.mad_mimi_api-provider label').click

    fill_in 'contact_list[data][username]', with: 'tj+madmimitest@polymathic.me'
    fill_in 'contact_list[data][api_key]', with: '12225410b3e4b656e09ce7760bfaa240'

    find('.button.ready').click
    select 'TEST LIST', :from => 'Choose a MadMimi list to sync with'
    find('.button.submit').click

    expect(page).to have_content('MadMimi list "TEST LIST"')

    find('#edit-contact-list').click
    find('.button.unlink').click

    Hellobar::Settings[:fake_data_api] = fake_data_api_original
  end

  #----------  MadMimi - Variant  ----------#

  scenario 'connect to MadMimi - variant email integration UI' do
    stub_out_get_ab_variations('Email Integration UI 2016-06-22') {'variant'}

    fake_data_api_original = Hellobar::Settings[:fake_data_api]
    Hellobar::Settings[:fake_data_api] = true

    site = @user.sites.create(url: random_uniq_url)
    contact_list = create(:contact_list, site: site)

    visit site_contact_list_path(site, contact_list)

    find('#edit-contact-list').click
    find('a', text: 'Nevermind, I want to view all tools').click
    find('label', text: 'MadMimi').click

    fill_in 'contact_list[data][username]', with: 'tj+madmimitest@polymathic.me'
    fill_in 'contact_list[data][api_key]', with: '12225410b3e4b656e09ce7760bfaa240'

    find('.button.ready').click
    select 'TEST LIST', :from => 'Choose a MadMimi list to sync with'
    find('.button.submit').click

    expect(page).to have_content('MadMimi list "TEST LIST"')

    find('#edit-contact-list').click
    find('.button.unlink').click

    Hellobar::Settings[:fake_data_api] = fake_data_api_original
  end

  #----------  Webhooks - Original  ----------#

  scenario 'setting up a new contact list with webhooks' do
    fake_data_api_original = Hellobar::Settings[:fake_data_api]
    Hellobar::Settings[:fake_data_api] = true

    site = @user.sites.create(url: random_uniq_url)
    contact_list = create(:contact_list, site: site)

    visit site_contact_list_path(site, contact_list)

    find('#edit-contact-list').click

    find('a', text: 'Nevermind, I want to view all tools').click
    find('.webhooks-provider label').click

    fill_in 'contact_list[data][webhook_url]', with: 'http://google.com'
    check 'POST request'
    find('.button.submit').click
    expect(page).to have_selector("input[value='Export CSV']")

    find('#edit-contact-list').click

    expect(page).to have_content('POST request')
    expect(find('#contact_list_webhook_url').value).to eq 'http://google.com'
    expect(find('#contact_list_provider').value).to eq 'webhooks'

    Hellobar::Settings[:fake_data_api] = fake_data_api_original
  end

  #----------  Webhooks - Variant  ----------#

  scenario 'updating an existing contact list to be a webhook' do
    stub_out_get_ab_variations('Email Integration UI 2016-06-22') {'variant'}

    fake_data_api_original = Hellobar::Settings[:fake_data_api]
    Hellobar::Settings[:fake_data_api] = true

    site = @user.sites.create(url: random_uniq_url)
    contact_list = create(:contact_list, site: site)

    visit site_contact_list_path(site, contact_list)
    find('#edit-contact-list').click

    find('a', text: 'Nevermind, I want to view all tools').click
    find('label', text: 'Webhooks').click
    fill_in 'contact_list[data][webhook_url]', with: 'http://google.com'
    check 'POST request'

    find('.button.submit').click
    find('#edit-contact-list').click

    expect(page).to have_content('Webhook URL')
    expect(find('#contact_list_webhook_url').value).to eq 'http://google.com'
    expect(find('#contact_list_provider').value).to eq 'webhooks'

    Hellobar::Settings[:fake_data_api] = fake_data_api_original
  end
end
