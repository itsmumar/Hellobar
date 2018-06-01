namespace :system_metrics do
  desc 'Upload system metrics to Amplitude'
  task upload: :environment do
    TrackSystemMetrics.new.call
  end
end
