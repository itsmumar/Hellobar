class ApplicationJob < ActiveJob::Base
  queue_as { "hb3_#{ Rails.env }_lowpriority" }

  rescue_from StandardError do |exception|
    Raven.capture_exception exception
  end

  before_perform do |job|
    Raven.extra_context arguments: job.arguments, job_id: job.job_id, queue_name: job.queue_name
    Raven.tags_context job: job.class.to_s
  end
end
