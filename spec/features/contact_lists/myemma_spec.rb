require 'integration_helper'

feature 'MyEmma Integration', :js, :contact_list_feature do
  let(:provider) { 'icontact' }

  let!(:user) { create :user }
  let!(:site) { create :site, :with_bars, user: user }
  let(:embed_code) { create :embed_code, provider: 'icontact' }

  before do
    sign_in user
    allow_any_instance_of(ExtractEmbedForm)
      .to receive(:request_embed_url).and_return(create(:embed_code, provider: 'icontact_script'))
  end

  context 'when invalid' do
    before { allow(ServiceProvider).to receive(:new).and_return(double(connected?: false, lists: [])) }

    let(:embed_code) { 'invalid' }

    scenario 'displays error' do
      connect
      expect(page).to have_content('Embed code is invalid')
    end
  end

  scenario 'when valid' do
    connect
    expect(page.find('#contact_list_embed_code').value).to eql embed_code
  end

  private

  def connect
    open_provider_form(user, provider)
    fill_in 'contact_list[data][embed_code]', with: embed_code
    page.find('.button.submit').click
  end
end
