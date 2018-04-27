module UserHelper
  def display_name_for_user(user)
    display_name =
      if user.first_name.present? && user.last_name.present?
        "#{ user.first_name } #{ user.last_name[0, 1] }."
      else
        user.first_name.presence || user.email
      end

    truncate(display_name, length: 30)
  end

  def gravatar_url_for(user, opts = {})
    email = OpenStruct.new(email: user.email.presence || 'none')
    url = avatar_url_for(email, opts)

    # avatar gem doesn't support adding a non-url string to the d/default param
    # This param changes the default gravatar image to "mystery man"
    url << (url.include?('?') ? '&' : '?')
    url << 'd=mm'
  end

  def google_sign_in_button
    content_tag :button, type: :submit, class: 'button google-sign-in-button', name: 'signup_with_google' do
      safe_join([
        content_tag(:i, nil, class: 'icon'),
        content_tag(:span, 'Use your Google account', class: 'label')
      ])
    end
  end

  def terms_of_use_link
    link_to 'Terms of Use', terms_of_use_url, target: '_blank'
  end

  def privacy_policy_link
    link_to 'Privacy Policy', privacy_policy_url, target: '_blank'
  end

  def accept_terms_and_conditions_label
    content_tag :span, class: 'terms-and-conditions' do
      "I agree to the Hello Bar #{ terms_of_use_link } & #{ privacy_policy_link }".html_safe # rubocop:disable Rails/OutputSafety
    end
  end

  def display_terms_and_condition_updated?
    current_user.created_at < User::NEW_TERMS_AND_CONDITIONS_EFFECTIVE_DATE
  end

  def display_referral_announcement?(site)
    current_user.was_referred? && site.free?
  end

  def embed_analytics?
    Rails.env.production? && !current_user&.pro_managed?
  end
end
