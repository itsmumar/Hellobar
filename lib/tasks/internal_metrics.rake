namespace :internal_metrics do
  desc 'Emails a weekly metrics update to business people'
  task summary: :environment do
    InternalMetricsMailer.summary.deliver_now
  end
end
