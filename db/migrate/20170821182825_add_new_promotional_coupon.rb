class AddNewPromotionalCoupon < ActiveRecord::Migration
  def up
    Coupon.create! label: Coupon::PROMOTIONAL_LABEL, amount: Coupon::PROMOTIONAL_AMOUNT, public: true
  end

  def down
    Coupon.where(label: Coupon::PROMOTIONAL_LABEL).destroy_all
  end
end
