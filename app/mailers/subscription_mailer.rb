class SubscriptionMailer < ApplicationMailer
  layout 'user_mailer'

  default from: 'Hello Bar <contact@hellobar.com>'

  def downgrade_to_free(site, user)
    @site = site
    @user = user

    mail(
      to: user.email,
      subject: "Your Hello Bar subscription for #{site.url} have been downgraded to Free",
      layout: 'user_mailer'
    )
  end
end
