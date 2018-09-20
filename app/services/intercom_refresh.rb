class IntercomRefresh
  def call
    refresh
  end

  private

  attr_reader :current_user

  def refresh
    @users = []
    Site.active.find_in_batches do |group|
      group.each do |site|
        check_site_for_dme(site)
        site.users.each do |user|
          @users << user
        end
      end
    end
    @users = @users.uniq
    track_updated_site_counts
  end

  def track_updated_site_counts
    @users.each do |user|
      TrackEvent.new(:update_site_count, user: user).call
    end
  end

  def check_site_for_dme(site)
    if site.active_subscription&.type == 'Subscription::ProComped' || site.active_subscription&.type == 'Subscription::Elite' || site.active_subscription&.type == 'Subscription::ProManaged'
      track_dme(site)
    elsif site.active_subscription&.type == 'Subscription::Pro' || site.active_subscription&.type == 'Subscription::Growth'
      handle_trial_dme(site)
    end
  end

  def handle_trial_dme(site)
    track_dme(site) if site.active_subscription&.created_at >= (Time.zone.today - 90.days) # rubocop:disable Lint/SafeNavigationChain
  end

  def track_dme(site)
    site.users.each do |user|
      TrackEvent.new(:add_dme, user: user)
    end
  end
end
