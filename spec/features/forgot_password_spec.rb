require 'integration_helper'

feature 'Forgot password', :js do
  given(:email) { 'bob@lawblog.com' }
  given!(:user) { create :user, email: email }

  around { |example| perform_enqueued_jobs(&example) }

  before do
    allow(Settings).to receive(:deliver_emails).and_return true
    visit new_user_session_path
    click_on 'Forgot your password?'
    fill_in 'user_email', with: email
    click_on 'Send Reset Instructions'

    expect(page).to have_content('you will receive a password recovery link at your email address')
    @reset_password_link = links_in_email(last_email_sent).first
    uri = URI.parse(@reset_password_link)
    @reset_password_path = "#{ uri.path }?#{ uri.query }"
  end

  scenario 'invalid token' do
    visit @reset_password_path + 'invalid-characters'
    fill_form

    expect(page).to have_content('Reset password token is invalid')
  end

  scenario 'successfully reset password' do
    visit @reset_password_path
    fill_form

    expect(page).to have_content('Your password was changed successfully. You are now signed in')
  end

  def fill_form
    expect(page).to have_content('Change Your Password')

    fill_in 'user_password',              with: 'newpassword'
    fill_in 'user_password_confirmation', with: 'newpassword'
    submit_form
  end
end
