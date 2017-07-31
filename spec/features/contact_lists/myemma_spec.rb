require 'integration_helper'

feature 'MyEmma Integration', :js, :contact_list_feature do
  let(:provider) { 'my_emma' }

  let!(:user) { create :user }
  let!(:site) { create :site, :with_bars, user: user }
  let(:embed_code) { create :embed_code, provider: 'my_emma_iframe' }

  before do
    sign_in user
    allow_any_instance_of(ExtractEmbedForm)
      .to receive(:request_embed_url).and_return(create(:embed_code, provider: 'my_emma_form'))
  end

  context 'when invalid' do
    let(:embed_code) { 'invalid' }

    scenario 'displays error' do
      connect
      expect(page).to have_content('Embed code is invalid')
    end
  end

  scenario 'when valid' do
    connect
    expect(page.find('#contact_list_embed_code').value).to eql embed_code
    expect(page).to have_content 'Syncing contacts with MyEmma'
  end

  private

  def connect
    open_provider_form(site, provider)
    fill_in 'contact_list[data][embed_code]', with: embed_code
    page.find('.button.submit').click
  end
end
