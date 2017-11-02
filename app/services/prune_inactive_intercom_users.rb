class PruneInactiveIntercomUsers
  PRUNING_THRESHOLD = 3.days

  def initialize inactivity_threshold:
    @inactivity_threshold = inactivity_threshold
  end

  def call
    prune_inactive_users
  end

  private

  attr_reader :inactivity_threshold

  def prune_inactive_users
    inactive_users.uniq.each do |user|
      next unless (intercom_user = intercom.find_user(user.id))

      log user
      intercom.delete_user intercom_user
    end
  end

  def log user
    info = "Deleting User##{ user.id } at Intercom (#{ user.email }, " \
      "#{ user.sites.count } site(s), subscriptions: " \
      "#{ user.subscriptions.active.map(&:type).join(', ') }, " \
      "user updated_at: #{ user.updated_at }, " \
      "sites updated_at: #{ user.sites.map(&:updated_at).sort.join(', ') })"

    puts info unless Rails.env.test? # rubocop:disable Rails/Output
  end

  def inactive_users
    inactive_sites.each.with_object([]) do |site, users|
      site.owners.each do |owner|
        next if owner.paying_subscription?
        next if owner.updated_at > @inactivity_threshold.ago
        next if owner.sites.any? { |s| s.updated_at > @inactivity_threshold.ago }
        next if owner.sites.any?(&:script_installed?)

        users << owner
      end
    end
  end

  def inactive_sites
    Site
      .script_not_installed
      .where('updated_at < ?', @inactivity_threshold.ago)
      .where('updated_at > ?', (@inactivity_threshold + PRUNING_THRESHOLD).ago)
  end

  def intercom
    IntercomGateway.new
  end
end
