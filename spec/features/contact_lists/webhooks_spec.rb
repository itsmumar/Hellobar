require 'integration_helper'

feature 'Webhooks Integration', :js, :contact_list_feature do
  let(:provider) { 'webhooks' }

  let!(:user) { create :user }
  let!(:site) { create :site, :with_bars, user: user }

  before do
    sign_in user
  end

  context 'when invalid' do
    scenario 'empty url' do
      connect('')
      expect(page).to have_content('webhook URL cannot be blank')
    end

    scenario 'invalid host' do
      connect('http://foobarbaz')
      expect(page).to have_content('could not connect to the webhook URL')
    end

    scenario 'not a http/https' do
      connect('ftp://foobarbaz')
      expect(page).to have_content('webhook protocol must be either http or https')
    end
  end

  scenario 'when valid' do
    connect('http://localhost')

    expect(page.find('#contact_list_webhook_url').value).to eql 'http://localhost'
    expect(page).to have_content 'Syncing contacts with Webhooks'
  end

  private

  def connect(url)
    open_provider_form(site, provider)
    fill_in 'contact_list[data][webhook_url]', with: url
    page.find('.button.submit').click
  end
end
