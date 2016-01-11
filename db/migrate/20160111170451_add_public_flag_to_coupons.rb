class AddPublicFlagToCoupons < ActiveRecord::Migration
  def change
    add_column :coupons, :public, :boolean, default: false
  end
end
