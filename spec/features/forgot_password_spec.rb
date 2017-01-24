require 'integration_helper'

feature 'Forgot password', :js do
  given(:email) { 'bob@lawblog.com' }
  given(:user) { create :user, email: email }

  before do
    visit new_user_session_path
    click_on 'Forgot your password?'
  end

  context 'show default notification' do
    after(:each) do
      click_on 'Send Reset Instructions'
      expect(page).to have_content('you will receive a password recovery link at your email address in a few minutes')
    end

    scenario 'if email exists in db' do
      fill_in 'user_email', with: email
    end

    scenario 'show default notification even if email doesn\'t exists in db' do
      fill_in 'user_email', with: 'i-am-not-bob@lawblog.com'
    end
  end

  context 'reset password link' do
    before(:each) do
      fill_in 'user_email', with: email
      click_on 'Send Reset Instructions'

      @reset_pwd_link = "http://localhost:3000/users/password/edit.#{user.id}?" +
                          "reset_password_token=#{user.reset_password_token}"
    end

    scenario 'invalid token' do
      visit @reset_pwd_link + "invalid-characters"
      expect(page).to have_content('Change Your Password')

      fill_in 'user_password',              with: 'newpassword'
      fill_in 'user_password_confirmation', with: 'newpassword'

      expect(page).to have_content('Reset password token is invalid')
    end
  end
end
