ActionMailer::DeliveryJob.queue_name_prefix = Rails.env
ActionMailer::DeliveryJob.queue_as :mailers
