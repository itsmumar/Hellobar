class AddRedemptionFieldsToReferrals < ActiveRecord::Migration
  def change
    add_column :referrals, :reedemed_by_sender_at, :datetime
    add_column :referrals, :redeemed_by_recipient_at, :datetime
  end
end
