require 'integration_helper'

feature 'Maropost Integration', :js, :contact_list_feature do
  let(:provider) { 'maropost' }

  let!(:user) { create :user }
  let!(:site) { create :site, :with_bars, user: user }

  before do
    sign_in user
  end

  context 'when invalid' do
    before { allow(ServiceProvider).to receive(:new).and_return(double(connected?: false, lists: [])) }

    scenario 'displays error' do
      connect
      expect(page).to have_content('There was a problem connecting your Maropost account')
    end
  end

  scenario 'when valid' do
    connect

    expect(page).to have_content('Choose a Maropost list to sync with')

    page.find('select#contact_list_remote_list_id').select('List 1')
    page.find('.button.submit').click

    expect(page).to have_content 'Syncing contacts with Maropost list "List 1"'

    page.find('#edit-contact-list').click

    expect(page).to have_content('List 1')
  end

  private

  def connect
    connect_to_provider(site, provider) do
      fill_in 'contact_list[data][username]', with: 'hellobar'
      fill_in 'contact_list[data][api_key]', with: 'api-key'
    end
  end
end
