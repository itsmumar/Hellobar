require 'integration_helper'
require 'service_provider_integration_helper'

feature 'Drip Integration', js: true do
  let(:provider) { 'drip' }

  before do
    OmniAuth.config.mock_auth[:drip] = OmniAuth::AuthHash.new(
      provider: 'drip',
      extra: { account_id: '8056783' },
      credentials: { token: '....' }
    )

    @fake_data_api_original = Hellobar::Settings[:fake_data_api]
    Hellobar::Settings[:fake_data_api] = true
    @user = login
  end

  after do
    Hellobar::Settings[:fake_data_api] = @fake_data_api_original
  end

  scenario 'displays campaigns and tags' do
    open_provider_form(@user, provider)
    page.find('.button.ready').click

    expect(page).to have_content('Choose a Drip campaign to sync with')
    expect(page).to have_content('Apply Tags (Optional)')
    expect(page).to have_link('+ Add tag')
  end
end
