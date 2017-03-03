module Admin::UsersHelper
  def bills_for(site)
    bills = Hash.new { |h, k| h[k] = [] } # Bill => [Refunds]
    site.bills.select do |b|
      b.subscription.nil? ||
        !b.subscription.instance_of?(Subscription::Free)
    end.sort_by(&:bill_at).reverse.each do |bill|
      if bill.instance_of?(Bill::Refund)
        bills[bill.refunded_billing_attempt.bill] << bill
      else
        bills[bill]
      end
    end
    bills
  end

  def subscriptions
    ObjectSpace.each_object(Class).select { |klass| klass < Subscription }
  end

  def bill_duration(bill)
    "#{us_short_datetime(bill.start_date)}-#{us_short_datetime(bill.end_date)}"
  end

  def site_info_or_form(site)
    if site.invoice_information.present?
      site.invoice_information.gsub("\r\n", "<br>").html_safe
    else
      render "sites/form", site: site
    end
  end

  def add_or_clear_site_info(site)
    if site.invoice_information.present?
      render "sites/form_remove_invoice_info", site: site
    else
      link_to('add', '#', class: 'add-invoice-info')
    end
  end

  def context_for_trial(user, bill)
    return nil unless bill.during_trial_subscription?
    if user.try(:wordpress_user_id).present?
      "via 1.0 trial"
    elsif user.try(:was_referred?)
      "via referral"
    else
      "via admin"
    end
  end

  private

  def us_short_datetime(datetime)
    datetime.to_date.to_s(:us_short)
  end
end
