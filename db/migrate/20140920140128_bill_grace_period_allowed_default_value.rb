class BillGracePeriodAllowedDefaultValue < ActiveRecord::Migration
  def change
    change_column :bills, :grace_period_allowed, :boolean, :default => true
  end
end
