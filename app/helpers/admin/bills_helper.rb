module Admin::BillsHelper
  COUPONS_SEPARATOR = ', '.freeze

  def bill_extra_days(bill)
    return trial_days(bill) if bill.subscription.trial_end_date && !bill.pending?

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

  def subscription_link(bill)
    Subscription.unscoped do
      subscription = bill.subscription
      title = "#{ subscription.values[:name] } ##{ subscription.id }"
      title += ' (trial)' if subscription.trial_end_date && !bill.pending?
      link_to title, admin_subscription_path(subscription)
    end
  end

  def bill_duration(bill)
    "#{ format_date(bill.start_date) } - #{ format_date(bill.end_date) }"
  end

  def bill_coupons(bill)
    bill.coupon_uses.map { |cu| cu.coupon&.label }.compact.join(COUPONS_SEPARATOR)
  end

  def bill_actions(bill)
    actions = []

    if bill.pending? || bill.failed?
      actions << link_to('pay',
        pay_admin_bill_path(bill),
        method: :put, data: { confirm: 'Pay this bill?' })

      actions << link_to('void',
        void_admin_bill_path(bill),
        method: :put,
        data: { confirm: 'Void this bill?' })
    end

    if !bill.voided? && bill.amount == 0
      actions << link_to('void',
        void_admin_bill_path(bill),
        method: :put, data: { confirm: 'Void this bill?' })
    end

    if bill.paid? && !bill.refund && !bill.chargeback && bill.amount != 0
      actions << render('admin/bills/refund_form', bill: bill)
      actions << link_to('chargeback',
        chargeback_admin_bill_path(bill),
        method: :put, data: { confirm: 'Chargeback this bill?' })
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
