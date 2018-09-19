class HandleUnfreezeFrozenAccount
  def initialize(site)
    @site = site
  end

  def call
    handle_unfreeze
  end

  private

  attr_reader :site

  def handle_unfreeze
    @site.activate_site_element
    # OveragePaidMailer.unfreeze_email(site).deliver_later
  end
end
