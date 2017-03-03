module ReferralsHelper
  def referral_url_for_user(user)
    accept_referrals_url(token: user.referral_token.token)
  end

  def icon_for_referral(referral)
    if referral.state.present?
      image_tag "referrals/#{referral.state}.svg", class: 'referral-img'
    else
      ''
    end
  end

  def text_for_referral(referral)
    if referral.state.present?
      I18n.t("referral.state.#{referral.state}")
    else
      ''
    end
  end
end
