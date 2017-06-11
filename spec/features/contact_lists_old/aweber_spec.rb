require 'integration_helper'

feature 'AWeber Integration', :js, :contact_list_feature do
  let(:provider) { 'aweber' }

  let!(:user) { create :user }
  let!(:site) { create :site, :with_bars, user: user }

  before do
    sign_in user
  end

  context 'when invalid' do
    before { allow(ServiceProvider).to receive(:new).and_return(double(connected?: false, lists: [])) }

    scenario 'displays error' do
      connect
      expect(page).to have_content('There was a problem connecting your AWeber account')
    end
  end

  scenario 'when valid' do
    connect

    expect(page).to have_content('Choose a AWeber list to sync with')
    selector = 'select#contact_list_remote_list_id'

    page.find(selector).select('List 1')
    page.find('.button.submit').click

    page.find('#edit-contact-list').click

    expect(page).to have_content('List 1')
  end

  private

  def connect
    connect_to_provider(user, provider)
  end
end
