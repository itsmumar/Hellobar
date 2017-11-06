class DowngradeSiteToFree
  def initialize(site)
    @site = site
  end

  def call
    void_pending_bills
    create_free_subscription unless currently_on_free?
    enable_branding_on_all_bars
  end

  private

  attr_reader :site

  def currently_on_free?
    site.free?
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
end
