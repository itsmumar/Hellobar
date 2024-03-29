module SitesHelper
  def site_has_payment_issue?(site)
    site.present? && site.bills_with_payment_issues.present?
  end

  def payment_issue_amount(site)
    site_has_payment_issue?(site) ? site.bills_with_payment_issues.sum(:amount) : 0
  end

  def payment_issue_date(site)
    site_has_payment_issue?(site) ? site.bills_with_payment_issues.first.bill_at : nil
  end

  def install_help_data(site)
    case site.install_type
    when 'weebly'
      ['Weebly', 'https://support.hellobar.com/installation/how-to-install-hello-bar-on-weebly/']
    when 'squarespace'
      ['Squarespace', 'https://support.hellobar.com/installation/how-to-install-hello-bar-on-squarespace/']
    when 'shopify'
      ['Shopify', 'https://support.hellobar.com/installation/how-to-install-hello-bar-on-shopify/']
    when 'blogspot'
      ['Blogger', 'https://support.hellobar.com/installation/how-to-install-hello-bar-on-blogger-or-blogspot/']
    end
  end

  def format_role(site_membership)
    site_membership.try(:role) || :none
  end

  def sites_for_team_view(user = current_user, target_site = current_site)
    user.sites.sort_by { |site| [site == target_site ? 0 : 1, site.url.downcase] }
  end

  def sorted_sites
    current_user.sites.sort_by { |s| s.host || '' }
  end

  def bill_estimated_amount(bill)
    number_to_currency(bill.estimated_amount)
  end

  def subscription_days_left(site)
    return unless site.free? || site.active_subscription

    days = pluralize(site.active_subscription.days_left, 'day')
    "#{ days } left of #{ site.active_subscription.name } features"
  end

  def can_view_bills?(user, site)
    Permissions.view_bills?(user, site)
  end
end
