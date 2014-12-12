module Hello
  class WordpressModel < ActiveRecord::Base
    self.abstract_class = true

    begin
      establish_connection "wordpress_#{Rails.env}".to_sym
      @@connected = true
    rescue ActiveRecord::AdapterNotSpecified
      Rails.logger.warn "database wordpress_#{Rails.env} does not exist"
      @@connected = false
    end

    def self.deserialize(string)
      first_pass = PHP.unserialize(string)

      if first_pass.is_a?(Hash)
        return first_pass
      else
        match = string.match(/^\w+:\d+:\\*\"(.*)\\*\";$/)
        match ? PHP.unserialize(match[1]) : nil
      end
    end
  end
end

require_relative "./wordpress_bar"
require_relative "./wordpress_bar_meta"
require_relative "./wordpress_user"
