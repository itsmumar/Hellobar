class DestroySite
  def initialize(site)
    @site = site
  end

  def call
    void_pending_bills
    override_script
    site.destroy
  end

  private

  attr_reader :site

  def void_pending_bills
    site.bills.pending.each { |bill| bill.void! }
  end

  def override_script
    site.script.destroy
  end
end
