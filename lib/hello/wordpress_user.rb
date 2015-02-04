class Hello::WordpressUser < Hello::WordpressModel
  self.table_name = "hbwp_users"

  def self.email_exists?(email)
    @@connected ? (where(['user_email = ? or user_login = ?', email, email]).count >= 1) : false
  rescue ActiveRecord::NoDatabaseError
    Rails.logger.error("Wordpress database configured in database.yml does not exist")
    false
  end

  def self.authenticate(email, password, skip_password_check = false)
    user = where(['user_email = ? or user_login = ?', email, email]).first

    if skip_password_check
      user
    else
      user && Phpass.new.check(password, user.user_pass) ? user : nil
    end
  end

  def bars
    all_bars = Hello::WordpressBar.where(post_author: id)

    all_bars.select do |bar|
      if bar.post_parent.present? && bar.post_parent != 0
        parent = all_bars.find{|b| b.id == bar.post_parent}
        parent && parent.post_status == "publish" && bar.post_status == "publish"
      else
        bar.post_status == "publish"
      end
    end
  end

  def convert_to_user
    User.new(
      email: user_email.gsub("@", "+hbtemp@"),
      encrypted_password: user_pass
    ).tap{ |u| u.save(validate: false) }
  end
end
