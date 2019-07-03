namespace :inactive_user do
  desc 'check inactive users and add tags'
  task run: :environment do
    User.inactive_user.where('updated_at < ?', 30.days.ago).each do |user|
      TrackEvent.new(:inactive_user, user: user, site: user.sites.last).call
    end
  end
end
