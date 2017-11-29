class DowngradeSiteToFree
  def initialize(site)
    @site = site
  end

  def call
    void_pending_bills
    enable_branding_on_all_bars

    return if currently_on_free?

    create_free_subscription
    send_notification
  end

  private

  attr_reader :site

  def currently_on_free?
    site.current_subscription&.free?
  end

  def void_pending_bills
    site.bills.pending.each(&:voided!)
  end

  def create_free_subscription
    Subscription::Free.create!(site: site)
  end

  def enable_branding_on_all_bars
    site.site_elements.update_all show_branding: true
  end

  def send_notification
    site.users.each do |user|
      SubscriptionMailer.downgrade_to_free(site, user).deliver_later
    end
  end
end
