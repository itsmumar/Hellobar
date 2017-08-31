class TeamMailer < ApplicationMailer
  default from: 'Hello Bar <contact@hellobar.com>'

  def invite(user, site)
    if user.temporary? && !user.invite_token_expired?
      return invite_new_user(user, site)
    end

    @site = site
    @login_url = user.oauth_user? ? oauth_url(action: 'google_oauth2') : new_user_session_url

    params = {
      subject: 'You\'ve been added to a Hello Bar team.',
      to: user.email
    }

    mail params
  end

  private

  def invite_new_user(user, site)
    @site = site
    @user = user

    params = {
      subject: 'You\'ve been added to a Hello Bar team.',
      to: user.email,
      template_name: 'invite_new_user'
    }

    mail params
  end
end
