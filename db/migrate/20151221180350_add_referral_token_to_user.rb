class AddReferralTokenToUser < ActiveRecord::Migration
  def change
    add_column :users, :referral_token, :string
    User.reset_column_information
    User.find_each { |user| user.save }
  end
end
