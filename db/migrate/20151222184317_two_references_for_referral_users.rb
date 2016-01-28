class TwoReferencesForReferralUsers < ActiveRecord::Migration
  def change
    rename_column :referrals, :user_id, :sender_id
    add_column :referrals, :recipient_id, :integer
  end
end
