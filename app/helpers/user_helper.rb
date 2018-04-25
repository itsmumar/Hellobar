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
end
