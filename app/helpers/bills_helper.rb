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

  def bill_address_info(site, details)
    if site.invoice_information.present?
      '<br>' + site.invoice_information.gsub("\r\n", '<br>')
    elsif details.address.present?
      "<br>#{ details.address.address1 }
       <br>#{ details.address.city }
       <br>#{ details.address.state } #{ details.address.zip } #{ details.address.country }"
    end
  end

  def credit_card_description(credit_card)
    return unless credit_card
    "#{ credit_card.brand.capitalize } ending in #{ credit_card.last_digits }"
  end
end
