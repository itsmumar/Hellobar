require "cgi"

module Drip
  class Client
    module Tags
      def tags
        get "#{account_id}/tags"
      end
    end
  end
end
