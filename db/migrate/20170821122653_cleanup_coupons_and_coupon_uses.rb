class CleanupCouponsAndCouponUses < ActiveRecord::Migration
  def up
    remove_column :coupons, :available_uses

    change_column_null :coupons, :label, false
    change_column_null :coupons, :amount, false
    change_column_null :coupons, :created_at, false
    change_column_null :coupons, :updated_at, false
    change_column_null :coupons, :public, false

    change_column_null :coupon_uses, :coupon_id, false
    change_column_null :coupon_uses, :bill_id, false
    change_column_null :coupon_uses, :created_at, false
    change_column_null :coupon_uses, :updated_at, false

    add_foreign_key :coupon_uses, :coupons
    add_foreign_key :coupon_uses, :bills
  end

  def down
    add_column :coupons, :available_uses, :integer

    change_column_null :coupons, :label, true
    change_column_null :coupons, :amount, true
    change_column_null :coupons, :created_at, true
    change_column_null :coupons, :updated_at, true
    change_column_null :coupons, :public, true

    change_column_null :coupon_uses, :coupon_id, true
    change_column_null :coupon_uses, :bill_id, true
    change_column_null :coupon_uses, :created_at, true
    change_column_null :coupon_uses, :updated_at, true

    remove_foreign_key :coupon_uses, :coupons
    remove_foreign_key :coupon_uses, :bills
  end
end
