namespace :intercom_refresh do
  desc 'Check monthly views limits'
  task start: :environment do
    IntercomRefresh.new.call
  end
end
