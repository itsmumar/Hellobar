class ApplicationJob < ActiveJob::Base
  queue_as Settings.low_priority_queue
end
