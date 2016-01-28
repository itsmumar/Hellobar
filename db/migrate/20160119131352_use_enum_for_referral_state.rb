class UseEnumForReferralState < ActiveRecord::Migration
  def change
    remove_column :referrals, :state
    add_column :referrals, :state, :integer, default: 0
  end
end
