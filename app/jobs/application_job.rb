class ApplicationJob < ActiveJob::Base
  queue_as { "hb3_#{ Rails.env }_lowpriority" }
end
