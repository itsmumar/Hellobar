require 'integration_helper'

feature 'Hello Bar Integration', :js, :contact_list_feature do
  let(:provider) { '0' }

  let!(:user) { create :user }
  let!(:site) { create :site, :with_bars, user: user }

  before do
    sign_in user
  end

  scenario 'creates contact list without provider' do
    visit site_contact_lists_path(site)
    page.find('#new-contact-list').click

    page.find('a', text: 'I don\'t use any of these email tools').click
    page.find('.button.submit').click

    expect(page).to have_content 'Storing contacts in Hello Bar'
  end
end
