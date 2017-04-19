require 'integration_helper'

feature 'Lead data popup', :js do
  given(:user) { create :user }

  after do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  before do
    allow_any_instance_of(ApplicationController)
      .to receive(:needs_filling_questionnaire?).and_return(true)
  end

  scenario 'new user must fill out questionnaire' do
    OmniAuth.config.add_mock(:google_oauth2, uid: '12345', info: { email: user.email })

    visit root_path

    fill_in 'site[url]', with: 'mewgle.com'
    click_button 'sign-up-button'

    expect(page).to have_content 'Are you sure you want to add the site'

    click_on 'Create Site'

    expect(page).to have_content 'WE HAVE JUST A FEW QUESTIONS TO HELP YOU GET THE MOST OUT OF HELLO BAR'

    select 'eCommerce', from: 'industry'
    select 'Marketing', from: 'job_role'
    find(:label, '1-10').click
    find(:label, '10 000').click
    find(:label, 'Generate More Sales').click
    click_on 'Next'

    find(:label, 'Yes').click
    fill_in 'phone_number', with: '+1-234-567-8910'
    click_on 'Submit'
    wait_for_ajax

    attributes = {
      industry: 'ecommerce',
      job_role: 'marketing',
      company_size: '1-10',
      estimated_monthly_traffic: '10 000',
      first_name: 'FirstName',
      last_name: 'LastName',
      challenge: 'generate more sales',
      interested: true,
      phone_number: '+12345678910'
    }
    expect(user.lead.reload.attributes).to include(attributes.stringify_keys)
  end
end
