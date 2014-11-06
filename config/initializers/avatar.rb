module Avatar
  module Source
    class GravatarSource
      def self.base_url_with_https
        'https://www.gravatar.com/avatar/'
      end

      # override base_url to include https
      class << self
        alias_method_chain :base_url, :https
      end
    end
  end
end
