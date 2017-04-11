require 'integration_helper'
require 'service_provider_integration_helper'

feature 'iContact integration', :js, :vcr do
  let(:provider) { 'icontact' }
  let(:script) { '<script type="text/javascript" src="https://app.icontact.com/icp/core/mycontacts/signup/designer/form/automatic?id=46&cid=1679071&lid=3205"></script>' }

  before do
    @fake_data_api_original = Hellobar::Settings[:fake_data_api]
    Hellobar::Settings[:fake_data_api] = true
    @user = login
  end

  after do
    Hellobar::Settings[:fake_data_api] = @fake_data_api_original
  end

  scenario 'connecting to iContact' do
    open_provider_form(@user, provider)

    expect(page).not_to have_css('.button.ready')

    fill_in 'contact_list[data][embed_code]', with: script
    find('.button.submit').click

    find('#edit-contact-list').click
    expect(find('[name="contact_list[data][embed_code]"]').value).to eql script
  end
end
