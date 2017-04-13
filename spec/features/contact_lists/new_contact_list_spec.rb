require 'integration_helper'
require 'service_provider_integration_helper'

feature 'New contact list screen', :js do
  let(:user) { create(:user, :with_email_bar) }
  let(:site) { user.sites.first }

  before do
    allow_any_instance_of(ApplicationController)
      .to receive(:ab_variation)
      .with('Upgrade Pop-up for Active Users 2016-08')
      .and_return('original')

    @fake_data_api_original = Hellobar::Settings[:fake_data_api]
    Hellobar::Settings[:fake_data_api] = true
    login user
  end

  after do
    Hellobar::Settings[:fake_data_api] = @fake_data_api_original
  end

  scenario 'displays favorite providers' do
    visit site_contact_lists_path(site)

    page.find('#new-contact-list').click

    expect(page).to have_css '.contact-list-radio-block.mailchimp-provider'
    expect(page).to have_css '.contact-list-radio-block.get_response_api-provider'
    expect(page).to have_css '.contact-list-radio-block.aweber-provider'
    expect(page).to have_css '.show-expanded-providers'
    expect(page).to have_css '.use-hello-bar-email-lists'
  end

  context 'when connect gives errors' do
    scenario 'displays error message' do
      visit site_contact_lists_path(site)

      page.find('#new-contact-list').click
      page.find('.show-expanded-providers').click
      page.find('.contact-list-radio-block.maropost-provider').click

      fill_in 'contact_list[data][username]', with: 'foo'
      fill_in 'contact_list[data][api_key]', with: 'bar'

      page.find('.button.ready').click

      expect(page.find('.contact-list-modal .flash-block.error.show'))
        .to have_content('There was a problem connecting your Maropost account. Please try again later.')
    end
  end
end
