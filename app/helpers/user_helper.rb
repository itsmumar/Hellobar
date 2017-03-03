module UserHelper
  def display_name_for_user(user)
    display_name =
      if !user.first_name.blank? && !user.last_name.blank?
        "#{user.first_name} #{user.last_name[0, 1]}."
      elsif !user.first_name.blank?
        user.first_name
      else
        user.email
      end

    truncate(display_name, :length => 30)
  end

  def gravatar_url_for(user, opts = {})
    email = OpenStruct.new(:email => user.email.blank? ? 'none' : user.email)
    url = avatar_url_for(email, opts)

    # avatar gem doesn't support adding a non-url string to the d/default param
    # This param changes the default gravatar image to "mystery man"
    if url.match(/\?/) # already has a query param
      url += '&d=mm'
    else
      url += '?d=mm'
    end
  end
end
