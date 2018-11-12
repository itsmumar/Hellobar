feature 'Iterable integration', :js, :contact_list_feature do
  let(:provider) { 'iterable' }

  let!(:user) { create :user }
  let!(:site) { create :site, :with_bars, :elite, user: user }

  before do
    sign_in user
    stub_provider(provider)
  end

  context 'when invalid' do
    before { allow(ServiceProvider).to receive(:new).and_return(double(connected?: false, lists: [])) }

    scenario 'displays error' do
      connect
      expect(page).to have_content('There was a problem connecting your Iterable account')
    end
  end

  scenario 'when valid' do
    connect

    expect(page).to have_content('Choose Iterable list to sync with')

    page.find('select#contact_list_remote_list_id').select('List 1')
    page.find('.button.submit').click

    expect(page).to have_content 'Syncing contacts with Iterable list'

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
