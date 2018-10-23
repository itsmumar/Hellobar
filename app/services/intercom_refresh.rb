class IntercomRefresh
  def call
    refresh
  end

  private

  attr_reader :current_user

  def refresh
    Site.active.find_each do |site|
      check_site_for_dme(site)
    end
  end

  def check_site_for_dme(site)
    track_dme(site) if site.current_subscription&.dme?
  end

  def track_dme(site)
    site.users.each do |user|
      find_highest_subscription(user)
    end
  end

  def find_highest_subscription(user)
    sub_names = user.sites.map { |site| site.current_subscription.name }
      if sub_names.include?('Elite') || sub_names.include?('Elite Special')
        'Elite'
      elsif sub_names.include?('Growth')
        'Growth'
      elsif sub_names.include?('Pro') || sub_names.include?('Pro Special')
        'Pro'
      elsif sub_names.include?('Pro Comped')
        'Pro Comped'
      elsif sub_names.include?('Pro Managed')
        'Pro Managed'
      elsif sub_names.include?('Custom 1')
        'Custom 1'
      elsif sub_names.include?('Custom 2')
        'Custom 2'
      elsif sub_names.include?('Custom 3')
        'Custom 3'
      else
        'Free'
      end
    # rubocop:enable Style/ConditionalAssignment
    TrackEvent.new(:added_dme, user: user, highest_subscription_name: highest_subscription_name).call
  end
end
