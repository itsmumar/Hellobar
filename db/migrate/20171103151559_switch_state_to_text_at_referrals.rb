class SwitchStateToTextAtReferrals < ActiveRecord::Migration
  def up
    add_column :referrals, :state_text, :string,
      null: false, default: Referral::SENT, limit: 20

    Referral.where(state: 0).update_all state_text: Referral::SENT
    Referral.where(state: 1).update_all state_text: Referral::SIGNED_UP
    Referral.where(state: 2).update_all state_text: Referral::INSTALLED
  end

  def down
    remove_column :referrals, :state_text
  end
end
