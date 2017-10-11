require 'integration_helper'

feature 'Email Campaigns management' do
  given(:user) { create :user }
  given(:site) { create :site, user: user }
  given!(:subscription) { create :subscription, :pro_managed, site: site }
  given!(:contact_list) { create :contact_list, site: site }

  given(:name) { 'Email rule' }
  given(:from_name) { 'Hello Bar' }
  given(:from_email) { 'me@example.com' }
  given(:subject) { 'Test subject' }
  given(:body) { 'Test body' }

  given(:new_name) { 'New Email rule' }

  before do
    login_as user, scope: :user, run_callbacks: false
  end

  scenario 'Adding, listing and editing an email_campaign' do
    visit root_path

    click_on 'Email Campaigns'

    expect(page.find('h1')).to have_content 'Email Campaigns'
  end
end
