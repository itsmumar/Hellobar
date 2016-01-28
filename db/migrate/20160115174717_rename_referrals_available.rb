class RenameReferralsAvailable < ActiveRecord::Migration
  def change
    rename_column :referrals, :available, :available_to_sender
  end
end
