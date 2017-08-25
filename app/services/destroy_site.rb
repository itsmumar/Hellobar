class DestroySite
  def initialize(site)
    @site = site
  end

  def call
    void_pending_bills
    generate_blank_static_assets
    site.destroy
  end

  private

  attr_reader :site

  def void_pending_bills
    site.bills.pending.map(&:voided!)
  end

  def generate_blank_static_assets
    GenerateAndStoreStaticScript.new(site, script_content: '').call
  end
end
