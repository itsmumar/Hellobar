module UserHelper
  def display_name_for_user(user)
    display_name = if !user.first_name.blank? && !user.last_name.blank?
      "#{user.first_name} #{user.last_name[0,1]}."
    elsif !user.first_name.blank?
      user.first_name
    else
      user.email
    end

    truncate(display_name, :length => 30)
  end
end
