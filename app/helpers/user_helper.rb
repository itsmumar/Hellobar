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
end
