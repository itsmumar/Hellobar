class AddTrialPeriodToCoupon < ActiveRecord::Migration
  def change
    add_column :coupons, :trial_period, :integer, default: 0, null: false
  end
end
