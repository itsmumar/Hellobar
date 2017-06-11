require 'integration_helper'

feature 'Infusionsoft Integration', :js, :contact_list_feature do
  let(:provider) { 'infusionsoft' }

  let!(:user) { create :user }
  let!(:site) { create :site, :with_bars, user: user }
  let(:last_contact_list) { ContactList.last }

  before do
    sign_in user
  end

  context 'when invalid' do
    before { allow(ServiceProvider).to receive(:new).and_return(double(connected?: false, lists: [])) }

    scenario 'displays error' do
      connect
      expect(page).to have_content('There was a problem connecting your Infusionsoft account')
    end
  end

  scenario 'when valid' do
    connect

    expect(page).to have_content('Apply Tags (Optional)')

    page.find('select[name="contact_list[remote_list_id]"]').select('Tag 1')
    page.find('.button.submit').click

    wait_for_ajax

    expect(last_contact_list.tags).to eql ['tag1']
  end

  private

  def connect
    connect_to_provider(user, provider) do
      fill_in 'contact_list[data][app_url]', with: 'hellobar.api-us1.com'
      fill_in 'contact_list[data][api_key]', with: 'api-key'
    end
  end
end
