module ReferralsHelper
  def referral_url_for_user(user)
    accept_referrals_url(token: user.referral_token.token)
  end

  def icon_for_referral(referral)
    if referral.state.in?(Referral::STATES.keys)
      state = referral.state
      image_tag "referrals/#{state}.svg", class: "referral-img"
    else
      ""
    end
  end

  def text_for_referral(referral)
    Referral::STATES[referral.state] || ""
  end
end
