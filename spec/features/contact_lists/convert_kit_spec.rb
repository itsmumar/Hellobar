require 'integration_helper'

feature 'ConvertKit integration', :js, :contact_list_feature do
  let(:provider) { 'convert_kit' }

  let!(:user) { create :user }
  let!(:site) { create :site, :with_bars, user: user }

  before do
    sign_in user
  end

  context 'when invalid' do
    before { allow(ServiceProvider).to receive(:new).and_return(double(connected?: false, lists: [])) }

    scenario 'displays error' do
      connect
      expect(page).to have_content('There was a problem connecting your ConvertKit account')
    end
  end

  scenario 'when valid' do
    connect

    expect(page).to have_content('Choose a ConvertKit form to sync with')

    find('select#contact_list_remote_list_id').select('List 1')
    find('.button.submit').click

    expect(page).to have_content 'Syncing contacts with ConvertKit list "List 1"'

    find('#edit-contact-list').click

    expect(page).to have_content('List 1')
  end

  private

  def connect
    connect_to_provider(site, provider) do
      fill_in 'contact_list[data][api_key]', with: 'valid-convertkit-key'
    end
  end
end
