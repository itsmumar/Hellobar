class ApplicationJob < ActiveJob::Base
  queue_as { "hb3_#{ Rails.env }_lowpriority" }

  rescue_from StandardError do |exception|
    Raven.capture_exception exception
  end
end
