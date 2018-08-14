namespace :monthly_views_tracker do
  desc 'Check monthly views limits'
  task check: :environment do
    CheckNumberOfViewsForSites.new.call
  end
end
