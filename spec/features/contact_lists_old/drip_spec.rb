require 'integration_helper'
require 'service_provider_integration_helper'

feature 'Drip Integration', :js, :vcr do
  let(:provider) { 'drip' }

  before do
    OmniAuth.config.mock_auth[:drip] = OmniAuth::AuthHash.new(
      provider: 'drip',
      extra: { account_id: '8056783' },
      credentials: { token: '....' }
    )

    allow(Settings).to receive(:fake_data_api).and_return true

    @user = login
  end

  scenario 'displays campaigns and tags' do
    open_provider_form(@user, provider)
    page.find('.button.ready').click

    expect(page).to have_content('Choose a Drip campaign to sync with')
    expect(page).to have_content('Apply Tags (Optional)')
    expect(page).to have_link('+ Add tag')
  end

  context 'when no tags' do
    scenario 'displays campaigns' do
      open_provider_form(@user, provider)
      page.find('.button.ready').click

      expect(page).to have_content('Choose a Drip campaign to sync with')
      expect(page).to have_content('Apply Tags (Optional)')
      expect(page).to have_link('+ Add tag')
      expect(page).to have_content('You have no tags in your Drip account')
    end
  end
end
