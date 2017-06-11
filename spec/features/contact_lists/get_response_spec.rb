require 'integration_helper'

feature 'GetResponse Integration', :js, :contact_list_feature do
  let(:provider) { 'get_response_api' }

  let!(:user) { create :user }
  let!(:site) { create :site, :with_bars, user: user }

  before do
    sign_in user
  end

  context 'when invalid' do
    before { allow(ServiceProvider).to receive(:new).and_return(double(connected?: false, lists: [])) }

    scenario 'displays error' do
      connect
      expect(page).to have_content('There was a problem connecting your GetResponse account')
    end
  end

  scenario 'when valid' do
    connect

    expect(page).to have_content('Choose a GetResponse list to sync with')

    page.find('select#contact_list_remote_list_id').select('List 1')
    page.find('.button.submit').click

    page.find('#edit-contact-list').click

    expect(page).to have_content('List 1')
  end

  private

  def connect
    connect_to_provider(site, provider) do
      fill_in 'contact_list[data][api_key]', with: 'api-key'
    end
  end
end
