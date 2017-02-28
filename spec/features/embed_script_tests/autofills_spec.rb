require 'integration_helper'

feature 'Autofills', :js do
  given(:site_element) { create :site_element, :bar, :email }
  given(:site) { site_element.site }
  given(:path) { generate_file_and_return_path site.id }
  given(:site_path) { site_path_to_url path }
  given(:email) { 'some@email.com' }
  given!(:autofill) { create :autofill, site: site }

  before do
    allow_any_instance_of(ScriptGenerator).to receive(:pro_secret).and_return 'random'
  end

  scenario 'email autofilling functionality' do
    visit site_path

    within_frame('random-container-0') do
      # we have to use `send_keys` so that the focus will be set on this
      # element, and blur() event will be triggered when we click the button
      find('#f-builtin-email').send_keys email

      click_on 'Click Here'
    end

    # reload the page to test if autofilling works
    visit site_path

    # expect input email field to contained an autofilled value
    expect(find('input.email').value).to eq email
  end
end
