class Hello::WordpressUser < Hello::WordpressModel
  self.table_name = "hbwp_users"

  def self.email_exists?(email)
    @@connected ? (where(['user_email = ? or user_login = ?', email, email]).count >= 1) : false
  rescue ActiveRecord::NoDatabaseError
    Rails.logger.error("Wordpress database configured in database.yml does not exist")
    false
  end

  def self.authenticate(email, password)
    user = where(['user_email = ? or user_login = ?', email, email]).first
    user && Phpass.new.check(password, user.user_pass) ? user : nil
  end

  def bars
    Hello::WordpressBar.where(post_author: id)
  end
end
