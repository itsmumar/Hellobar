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

  def marketing_site_link(title, path)
    link_to title, File.join(Settings.marketing_site_url, path), target: '_blank'
  end

  def blog_link
    marketing_site_link 'Blog', '/blog'
  end

  def terms_of_use_link
    marketing_site_link 'Terms of Use', '/terms-of-use'
  end

  def privacy_policy_link
    marketing_site_link 'Privacy Policy', '/privacy-policy'
  end

  def gdpr_notice_link
    marketing_site_link 'GDPR Notice', '/gdpr'
  end

  def accept_terms_and_conditions_label
    content_tag :span, class: 'terms-and-conditions' do
      "I agree to the Hello Bar #{ terms_of_use_link } & #{ privacy_policy_link }".html_safe # rubocop:disable Rails/OutputSafety
    end
  end

  def display_terms_and_condition_updated?
    Settings.tos_updated_display == true && current_user.created_at < User::NEW_TERMS_AND_CONDITIONS_EFFECTIVE_DATE
  end

  def display_referral_announcement?(site)
    current_user.was_referred? && site.free?
  end

  def embed_analytics?
    Rails.env.production? && !current_user&.pro_managed?
  end
end
