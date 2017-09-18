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
      ['Weebly', 'http://support.hellobar.com/how-do-i-install-hello-bar-on-weebly/']
    when 'squarespace'
      ['Squarespace', 'http://support.hellobar.com/how-do-i-install-hello-bar-on-squarespace/']
    when 'shopify'
      ['Shopify', 'http://support.hellobar.com/how-do-i-install-hello-bar-on-shopify/']
    when 'blogspot'
      ['Blogger', 'http://support.hellobar.com/how-do-i-istall-hello-bar-on-bloggerblogspot/']
    end
  end

  def format_role(site_membership)
    site_membership.try(:role) || :none
  end

  def sites_for_team_view
    current_user.sites.sort_by { |site| [site == current_site ? 0 : 1, site.url.downcase] }
  end

  def bill_due_at(bill)
    bill.due_at.strftime('%-m-%-d-%Y')
  end

  def bill_estimated_amount(bill)
    number_to_currency(bill.estimated_amount)
  end
end
