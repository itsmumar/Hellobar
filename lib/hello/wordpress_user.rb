class Hello::WordpressUser < Hello::WordpressModel
  self.table_name = "hbwp_users"
  PRO_TRIAL_PERIOD = 14.days

  def self.email_exists?(email)
    find_by_email(email).present?
  end

  def self.find_by_email(email)
    @@connected ? where(['user_email = ? or user_login = ?', email, email]) : nil
  rescue ActiveRecord::NoDatabaseError
    Rails.logger.error("Wordpress database configured in database.yml does not exist")
    nil
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
    all_bars = Hello::WordpressBar.where(post_author: id, post_type: "hellobar")

    all_bars.select do |bar|
      if bar.post_parent.present? && bar.post_parent != 0
        parent = all_bars.find{|b| b.id == bar.post_parent}
        parent && parent.post_status != "trash" && bar.post_status != "trash"
      else
        bar.post_status != "trash"
      end
    end
  end

  def convert_to_user
    User.new(
      email: user_email,
      encrypted_password: user_pass,
      wordpress_user_id: id
    ).tap{ |u| u.save(validate: false) }
  end

  def is_pro_user?
    Hello::WordpressUserMeta.where(user_id: id, meta_key: "hellobar_vip_user").first.try(:meta_value) == "1" || \
    Hello::WordpressUserMeta.where(user_id: id, meta_key: "hbwp_s2member_subscr_id").first.try(:meta_value) != nil
  end
end
