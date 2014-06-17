module Hello
  class WordpressUser < ActiveRecord::Base
    begin
      establish_connection "wordpress_#{Rails.env}".to_sym
      self.table_name = "hbwp_users"

      @@connected = true
    rescue ActiveRecord::AdapterNotSpecified
      @@connected = false
    end

    def self.email_exists?(email)
      @@connected ? (where(['user_email = ? or user_login = ?', email, email]).count >= 1) : false
    rescue ActiveRecord::NoDatabaseError
      Rails.logger.error("Wordpress database configured in database.yml does not exist")
      false
    end
  end
end
