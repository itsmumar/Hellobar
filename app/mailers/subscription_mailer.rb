class SubscriptionMailer < ApplicationMailer
  default from: 'Hello Bar <contact@hellobar.com>'

  def downgrade_to_free(site, user, previous_subscription)
    @site = site
    @user = user
    @previous_subscription = previous_subscription

    mail(
      to: user.email,
      subject: "Your Hello Bar subscription for #{ site.url } has been downgraded to Free",
      layout: 'user_mailer'
    )
  end
end
