namespace :monthly_views_tracker do
  desc 'Check monthly views limits'
  task check: :environment do
    CheckMonthlyViewsLimits.new.call
  end
end
