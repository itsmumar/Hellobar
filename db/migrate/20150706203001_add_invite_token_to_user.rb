class AddInviteTokenToUser < ActiveRecord::Migration
  def change
    add_column :users, :invite_token, :string, index: true
    add_column :users, :invite_token_expire_at, :datetime
  end
end
