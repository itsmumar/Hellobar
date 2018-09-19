class HandleUnfreezeFrozenAccount
  def initialize(site)
    @site = site
    @current_subscription = site.current_subscription
  end

  def call
    handle_unfreeze
  end

  private

  attr_reader :site, :current_subscription

  def handle_unfreeze
    return unless current_subscription.current_subscription.active_bills.first.paid?
    current_bill = current_subscription.current_subscription.active_bills.first
    if current_bill.end_date == Date.current
      if site.site_elements.deactivated.present?
        site_element = site.site_elements.deactivated
        site_element.each(&:activate)
      end
      # OveragePaidMailer.unfreeze_email(site).deliver_later
    end
  end
end
