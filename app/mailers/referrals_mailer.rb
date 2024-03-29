class ReferralsMailer < ApplicationMailer
  helper ApplicationHelper

  default from: 'Hello Bar <contact@hellobar.com>'

  def invite(referral)
    @referral = referral

    params = {
      subject: "#{ referral.sender.name } has invited you to try Hello Bar",
      to: referral.email
    }

    mail params
  end

  def second_invite(referral)
    @referral = referral

    params = {
      subject: "#{ referral.sender.name }'s invitation is about to expire",
      to: referral.email
    }

    mail params
  end

  def successful(referral, user)
    @referral = referral
    @user = user

    params = {
      subject: "You Just Got a Free Bonus Month of Hello Bar #{ pro_or_growth }!",
      to: referral.sender.email
    }

    mail params
  end

  def pro_or_growth
    Subscription.pro_or_growth_for(@referral.sender).defaults[:name]
  end
end
