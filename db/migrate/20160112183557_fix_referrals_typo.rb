class FixReferralsTypo < ActiveRecord::Migration
  def change
    rename_column :referrals, :reedemed_by_sender_at, :redeemed_by_sender_at
  end
end
