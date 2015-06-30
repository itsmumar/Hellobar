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

  def show_whats_new_prompt?
    current_user &&
      current_user.created_at < Date.parse("2014-11-11") && # user was created before 3.0 launch
      Date.today < Date.parse("2014-11-18") &&              # it's within a week of 3.0 launch
      params["controller"] == "sites" &&                    # user is on the site summary page
      params["action"] == "show"
  end

  def install_help_data(site)
    case site.install_type
    when "weebly"
      ["Weebly", "http://support.hellobar.com/how-do-i-install-hello-bar-on-weebly/"]
    else
      nil
    end
  end
end
