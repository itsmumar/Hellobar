class DestroySite
  def initialize(site)
    @site = site
    @owners = site.owners
  end

  def call
    void_pending_bills
    override_script
    site.destroy
    track_site_count
  end

  private

  attr_reader :site

  def void_pending_bills
    site.bills.pending.each(&:void!)
  end

  def override_script
    site.script.destroy
  end

  def track_site_count
    TrackEvent.new(:updated_site_count, user: user).call
  end
end
