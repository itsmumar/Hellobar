require 'integration_helper'

feature 'Contact Submission' do
  before do
    @sent_email = []
    MailerGateway.stub(:send_email) do |type, recipient, params|
      @sent_email << {recipient: recipient, type: type, params: params}
    end
  end

  scenario 'page has correct content' do
    visit "/contact"
    expect(page).to have_content("We'd like to hear what's on your mind")
  end

  scenario 'user can create' do
    user = login
    visit "/contact"
    fill_in "contact_submission[name]", with: "Homer Simpson"
    fill_in "contact_submission[message]", with: "Test"
    find("#contact_submission_submit_btn").click

    expect(@sent_email.last[:params][:email]).to eq(user.email)
  end

  scenario 'non-user can create' do
    visit "/contact"
    fill_in "contact_submission[name]", with: "Bart Simpson"
    fill_in "contact_submission[email]", with: "bart@simpson.com"
    fill_in "contact_submission[message]", with: "Test"
    find("#contact_submission_submit_btn").click

    expect(@sent_email.last[:params][:email]).to eq("bart@simpson.com")
  end
end
