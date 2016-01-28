class CreateReferralTokens < ActiveRecord::Migration
  def change
    create_table :referral_tokens do |t|
      t.string :token
      t.integer :tokenizable_id
      t.string :tokenizable_type

      t.timestamps
    end
    remove_column :users, :referral_token

    User.reset_column_information
    ReferralToken.reset_column_information
    User.includes(:referral_token).find_each do |user|
      user.create_referral_token if user.referral_token.blank?
    end
  end
end
