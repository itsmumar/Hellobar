class AddIndexToReferralToken < ActiveRecord::Migration
  def change
    add_index :referral_tokens, [:tokenizable_id, :tokenizable_type]
  end
end
