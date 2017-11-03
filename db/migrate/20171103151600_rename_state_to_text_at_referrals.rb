class RenameStateToTextAtReferrals < ActiveRecord::Migration
  def up
    remove_column :referrals, :state
    rename_column :referrals, :state_text, :state
  end

  def down
    rename_column :referrals, :state, :state_text
    add_column :referrals, :state, :integer, default: 0
  end
end
