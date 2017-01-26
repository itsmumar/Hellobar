require 'integration_helper'

feature 'Forgot password', :js do
  given(:email) { 'bob@lawblog.com' }
  given(:user) { create :user, email: email }

  before do
    @sent_emails = []
    MailerGateway.stub(:send_email) do |type, recipient, params|
      @sent_emails << { recipient: recipient, type: type, params: params }
    end

    user.reload
    Hellobar::Settings[:deliver_emails] = true
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

      expect(page).to have_content('you will receive a password recovery link at your email address')
      @reset_password_link = @sent_emails.last[:params][:reset_link]
      uri = URI.parse(@reset_password_link)
      @reset_password_path = "#{uri.path}?#{uri.query}"
    end

    scenario 'send password recovery email' do
      expect(@sent_emails.count).to eq(1)
      expect(@sent_emails.last).to eq({
                                        :type => "Reset Password",
                                        :recipient => email,
                                        :params => {
                                          :email => email,
                                          :reset_link => @reset_password_link
                                        }
                                      })
    end

    scenario 'invalid token' do
      visit @reset_password_path + "invalid-characters"
      expect(page).to have_content('Change Your Password')

      fill_in 'user_password',              with: 'newpassword'
      fill_in 'user_password_confirmation', with: 'newpassword'
      submit_form

      expect(page).to have_content('Reset password token is invalid')
    end

    scenario 'successfully reset password' do
      visit @reset_password_path
      expect(page).to have_content('Change Your Password')

      fill_in 'user_password',              with: 'newpassword'
      fill_in 'user_password_confirmation', with: 'newpassword'
      submit_form

      expect(page).to have_content('Your password was changed successfully. You are now signed in')
    end

    context 'invalid password' do
      before(:each) do
        visit @reset_password_path
        expect(page).to have_content('Change Your Password')
      end

      scenario 'valid token but confirm password doesn\'t match' do
        fill_in 'user_password',              with: 'newpassword'
        fill_in 'user_password_confirmation', with: 'otherpassword'
        submit_form

        expect(page).to have_content('Password confirmation doesn\'t match Password')
      end

      scenario 'valid token but password too short' do
        fill_in 'user_password',              with: 'newpwd'
        fill_in 'user_password_confirmation', with: 'otherpwd'
        submit_form

        expect(page).to have_content('Password is too short (minimum is 8 characters)')
      end
    end
  end
end
