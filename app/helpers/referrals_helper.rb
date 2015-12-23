module ReferralsHelper
  def referral_url_for_user(user)
    accept_referrals_url(token: user.referral_token.token)
  end
end
