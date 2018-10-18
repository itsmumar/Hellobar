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
    # track_updated_site_counts # Disabled for now so that we don't crash Intercom...
  end

  def track_updated_site_counts
    @users.each do |user|
      TrackEvent.new(:update_site_count, user: user).call
    end
  end

  def check_site_for_dme(site)
    if site.current_subscription&.type == 'Subscription::ProComped' || site.current_subscription&.type == 'Subscription::Elite' || site.current_subscription&.type == 'Subscription::EliteSpecial' || site.current_subscription&.type == 'Subscription::ProManaged' || site.current_subscription&.type == 'Subscription::Custom1' || site.current_subscription&.type == 'Subscription::Custom2' || site.current_subscription&.type == 'Subscription::Custom3'
      track_dme(site)
    elsif site.current_subscription&.type == 'Subscription::Pro' || site.current_subscription&.type == 'Subscription::Growth' || site.current_subscription&.type == 'Subscription::ProSpecial'
      handle_trial_dme(site)
    end
  end

  def handle_trial_dme(site)
    track_dme(site) if site.current_subscription&.created_at >= (Time.zone.today - 90.days) # rubocop:disable Lint/SafeNavigationChain
  end

  def track_dme(site)
    site.users.each do |user|
      find_highest_subscription(user)
    end
  end

  def find_highest_subscription(user)
    sub_names = []
    user.sites.each do |site|
      sub_names << site.current_subscription.name
    end

    # rubocop:disable Style/ConditionalAssignment
    if sub_names.include?('Elite') || sub_names.include?('Elite Special')
      highest_subscription_name = 'Elite'
    elsif sub_names.include?('Growth')
      highest_subscription_name = 'Growth'
    elsif sub_names.include?('Pro') || sub_names.include?('Pro Special')
      highest_subscription_name = 'Pro'
    elsif sub_names.include?('Pro Comped')
      highest_subscription_name = 'Pro Comped'
    elsif sub_names.include?('Pro Managed')
      highest_subscription_name = 'Pro Managed'
    elsif sub_names.include?('Custom 1')
      highest_subscription_name = 'Custom 1'
    elsif sub_names.include?('Custom 2')
      highest_subscription_name = 'Custom 2'
    elsif sub_names.include?('Custom 3')
      highest_subscription_name = 'Custom 3'
    else
      highest_subscription_name = 'Free'
    end
    # rubocop:enable Style/ConditionalAssignment

    TrackEvent.new(:add_dme, user: user, highest_subscription_name: highest_subscription_name).call
  end
end
