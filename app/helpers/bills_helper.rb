module BillsHelper
  def coupons_and_uses(bill)
    bill.coupon_uses.includes(:coupon).group_by(&:coupon).each do |coupon, uses|
      yield coupon, uses.size
    end
  end

  def coupon_label(coupon, uses)
    label = "Coupon: #{ coupon.label } (#{ number_to_currency(coupon.amount) } each)"
    label += " &times; #{ uses }" if uses > 1
    label
  end

  def coupon_discount(coupon, uses)
    number_to_currency(-1 * uses * coupon.amount)
  end

  def bill_address_info(site, credit_card)
    if site.invoice_information.present?
      '<br>' + site.invoice_information.gsub("\r\n", '<br>')
    elsif credit_card.billing_address.present?
      "<br>#{ credit_card.billing_address.address1 }
       <br>#{ credit_card.billing_address.city }
       <br>#{ credit_card.billing_address.state } #{ credit_card.billing_address.zip }" \
       " #{ credit_card.billing_address.country }"
    end
  end
end
