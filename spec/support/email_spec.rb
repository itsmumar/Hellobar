# We need this because we use both Pony and ActionMailer
# but EmailSpec checks for Pony and use its deliveries
module EmailSpec
  module Deliveries
    def mailer
      ActionMailer::Base
    end

    def deliveries
      if ActionMailer::Base.delivery_method == :cache
        mailer.cached_deliveries
      else
        mailer.deliveries
      end
    end
  end
end

RSpec.configure do |config|
  config.include EmailSpec::Deliveries
end
