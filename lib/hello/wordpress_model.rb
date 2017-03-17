module Hello
  class WordpressModel < ActiveRecord::Base
    self.abstract_class = true

    begin
      establish_connection "wordpress_#{ Rails.env }".to_sym
      @connected = true
    rescue ActiveRecord::AdapterNotSpecified
      Rails.logger.warn "database wordpress_#{ Rails.env } does not exist"
      @connected = false
    end

    def self.deserialize(string)
      first_pass = PHP.unserialize(string)

      hash =
        if first_pass.is_a?(Hash)
          first_pass
        else
          match = string.match(/^\w+:\d+:\\*\"(.*)\\*\";$/)
          match ? PHP.unserialize(match[1]) : nil
        end

      return unless hash

      hash.inject({}) do |encoded_hash, (k, v)|
        k = k.is_a?(String) ? k.dup.force_encoding('utf-8') : k
        v = v.is_a?(String) ? v.dup.force_encoding('utf-8') : v

        encoded_hash.update k => v
      end
    end
  end
end

require_relative './wordpress_bar'
require_relative './wordpress_bar_meta'
require_relative './wordpress_user'
require_relative './wordpress_user_meta'
