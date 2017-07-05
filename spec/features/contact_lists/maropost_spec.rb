require 'integration_helper'

feature 'Maropost Integration', :js, :contact_list_feature do
  let(:provider) { 'maropost' }

  let!(:user) { create :user }
  let!(:site) { create :site, :with_bars, user: user }
  let(:last_contact_list) { ContactList.joins(:identity).where(identities: { provider: provider }).last }

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
    modal = connect
    modal.list = 'List 1'
    modal.tags = ['Tag 1']
    page = modal.done

    expect(page.title).to eql 'Syncing contacts with Maropost list "List 1"'

    modal = page.edit_contact_list

    expect(modal.selected_list).to eql 'List 1'
    expect(modal.selected_tags).to match_array ['Tag 1']
    expect(last_contact_list.tags).to match_array ['tag1', '']
  end

  private

  def connect
    ContactListsPage.visit(site).connect_contact_list(provider, username: 'hellobar', api_key: 'api-key')
  end
end
