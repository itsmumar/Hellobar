class ApplicationJob < ActiveJob::Base
  queue_as { "hb3_#{ Rails.env }_low_priority" }
end
