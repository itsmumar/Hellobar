class AddBodyToReferrals < ActiveRecord::Migration
  def change
    add_column :referrals, :body, :text
  end
end
