module Admin::BillsHelper
  COUPONS_SEPARATOR = ', '.freeze

  def bill_extra_days(bill)
    return trial_days(bill) if bill.subscription.trial_end_date

    expected_start_date = bill.end_date - bill.subscription.period
    difference = (expected_start_date - bill.start_date) / 1.day
    difference.zero? ? '' : difference.round
  end

  def trial_days(bill)
    period = bill.subscription.trial_period / 1.day
    period.round
  end

  def bills_for(site)
    Subscription.unscoped do
      site.bills.recurring.reorder(id: :desc)
    end
  end

  def subscriptions
    Subscription::ALL
  end

  def subscription_name(bill)
    Subscription.unscoped do
      name_and_id = "#{ bill.subscription.values[:name] } ##{ bill.subscription.id }"
      return "#{ name_and_id } (trial)" if bill.subscription.trial_end_date
      name_and_id
    end
  end

  def bill_duration(bill)
    "#{ us_short_datetime(bill.start_date) }-#{ us_short_datetime(bill.end_date) }"
  end

  def bill_coupons(bill)
    bill.coupon_uses.map { |cu| cu.coupon&.label }.compact.join(COUPONS_SEPARATOR)
  end

  def bill_actions(bill, site)
    actions = []

    if bill.pending? || bill.failed?
      actions << link_to('pay',
        pay_admin_site_bill_path(site, bill),
        method: :put, data: { confirm: 'Pay this bill?' })

      actions << link_to('void',
        void_admin_site_bill_path(site, bill),
        method: :put,
        data: { confirm: 'Void this bill?' })
    end

    if !bill.voided? && bill.amount == 0
      actions << link_to('void',
        void_admin_site_bill_path(site, bill),
        method: :put, data: { confirm: 'Void this bill?' })
    end

    if bill.paid? && !bill.instance_of?(Bill::Refund) && bill.amount != 0 # rubocop:disable Style/IfUnlessModifier
      actions << render('admin/bills/refund_form', bill: bill, site: site)
    end

    safe_join(actions, ' or ')
  end

  def credit_card_information(credit_card)
    return unless credit_card

    info = []
    info << content_tag(:p, credit_card.description)
    info << content_tag(:p, credit_card.name)
    info << content_tag(:p) do
      safe_join([
        credit_card.billing_address.address1,
        tag(:br),
        credit_card.billing_address.city,
        tag(:br),
        "#{ credit_card.billing_address.state } #{ credit_card.billing_address.zip }"
      ])
    end

    safe_join(info)
  end
end
