require 'integration_helper'

feature 'Contact Submission' do
  around { |example| perform_enqueued_jobs(&example) }

  scenario 'page has correct content' do
    visit '/contact'
    expect(page).to have_content("WE'D LIKE TO HEAR WHAT'S ON YOUR MIND")
  end

  scenario 'user can create' do
    user = login

    visit '/contact'

    fill_in 'contact_submission[name]', with: 'Homer Simpson'
    fill_in 'contact_submission[message]', with: 'Test'
    find('#contact_submission_submit_btn').click

    expect(last_email_sent.from).to eq([user.email])
  end

  scenario 'non-user can create' do
    visit '/contact'
    fill_in 'contact_submission[name]', with: 'Bart Simpson'
    fill_in 'contact_submission[email]', with: 'bart@simpson.com'
    fill_in 'contact_submission[message]', with: 'Test'
    find('#contact_submission_submit_btn').click

    expect(last_email_sent.from).to eq(['bart@simpson.com'])
  end
end
