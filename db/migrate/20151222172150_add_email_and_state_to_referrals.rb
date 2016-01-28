class AddEmailAndStateToReferrals < ActiveRecord::Migration
  def change
    add_column :referrals, :email, :string
    add_column :referrals, :state, :string
  end
end
