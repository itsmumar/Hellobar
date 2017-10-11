require 'integration_helper'

feature 'Email Campaigns management' do
  given(:user) { create :user }
  given(:site) { create :site, user: user }
  given!(:subscription) { create :subscription, :pro_managed, site: site }
  given!(:contact_list) { create :contact_list, site: site }

  given(:name) { 'Hello Bar Campaign' }
  given(:from_name) { 'Hello Bar' }
  given(:from_email) { 'me@example.com' }
  given(:campaign_subject) { 'Test subject' }
  given(:body) { 'Test body' }

  given(:new_name) { 'New Hello Bar Campaign' }

  before do
    login_as user, scope: :user, run_callbacks: false
  end

  scenario 'Adding, listing and editing an email_campaign' do
    visit root_path

    click_on 'Email Campaigns'

    expect(page.find('h1')).to have_content 'Email Campaigns'

    click_on 'New Email Campaign'

    expect(page).to have_content 'Create a new Email Campaign'

    within '.form-inputs' do
      select contact_list.name, from: 'email_campaign_contact_list_id'
      fill_in 'email_campaign_name', with: name
      fill_in 'email_campaign_from_name', with: from_name
      fill_in 'email_campaign_from_email', with: from_email
      fill_in 'email_campaign_subject', with: campaign_subject
      fill_in 'email_campaign_body', with: body
    end

    click_on 'Create Email campaign'

    within '.email-campaign' do
      expect(page).to have_content name
      expect(page).to have_content campaign_subject
      expect(page).to have_content contact_list.name

      click_on 'Edit'
    end

    expect(page). to have_content 'Edit Email Campaign'

    within '.form-inputs' do
      fill_in 'email_campaign_name', with: new_name
    end

    click_on 'Update Email campaign'

    expect(page).to have_content new_name
    expect(page).to have_content campaign_subject
    expect(page).to have_content EmailCampaign::NEW

    click_on 'Go back'

    expect(page).to have_content new_name
  end
end
