module SitesHelper
  def display_name_for_site(site)
    URI.parse(site.url).host
  rescue URI::InvalidURIError
    site.url
  end

  def site_has_payment_issue?(site)
    site.present? && site.bills_with_payment_issues.present?
  end

  def payment_issue_amount(site)
    site_has_payment_issue?(site) ? site.bills_with_payment_issues.inject(0){|sum,b| sum+=b.amount} : 0
  end

  def payment_issue_date(site)
    site_has_payment_issue?(site) ? site.bills_with_payment_issues.sort{|a,b| a.bill_at <=> b.bill_at}.first.bill_at : nil
  end
end
