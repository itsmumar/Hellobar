class PasswordMailer < ApplicationMailer
  default from: 'Hello Bar <support@hellobar.com>'

  def reset(user, reset_password_token)
    return reset_oauth(user) if user.oauth_user?

    @reset_password_token = reset_password_token

    params = {
      subject: 'Reset your password',
      to: user.email
    }

    mail params
  end

  private

  def reset_oauth(user)
    params = {
      subject: 'Reset your password',
      to: user.email
    }

    mail params do |format|
      format.html { render 'reset_oauth' }
      format.text { render 'reset_oauth' }
    end
  end
end
