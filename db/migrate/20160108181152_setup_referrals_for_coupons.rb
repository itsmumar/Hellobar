class SetupReferralsForCoupons < ActiveRecord::Migration
  def change
    add_column :referrals, :site_id, :integer
    add_column :referrals, :available, :boolean, default: false
  end
end
