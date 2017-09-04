class TeamMailer < ApplicationMailer
  layout 'user_mailer'
  default from: 'Hello Bar <contact@hellobar.com>'

  def invite(site_membership)
    user = site_membership.user
    site = site_membership.site

    if user.temporary? && !user.invite_token_expired?
      return invite_new_user(user, site)
    end

    @site = site
    @login_url = user.oauth_user? ? oauth_login_url(action: 'google_oauth2') : new_user_session_url

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
