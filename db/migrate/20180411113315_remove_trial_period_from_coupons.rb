class RemoveTrialPeriodFromCoupons < ActiveRecord::Migration
  def change
    remove_column :coupons, :trial_period, :integer, default: 0, null: false
  end
end
