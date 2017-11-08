namespace :intercom do
  desc 'Prune inactive users at Intercom'
  task prune_inactive_users: :environment do
    PruneInactiveUsersAtIntercom.new.call inactivity_threshold: 45.days
  end
end
