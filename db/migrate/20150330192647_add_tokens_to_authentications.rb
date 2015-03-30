class AddTokensToAuthentications < ActiveRecord::Migration
  def change
    add_column :authentications, :refresh_token, :string
    add_column :authentications, :access_token, :string
    add_column :authentications, :expires_at, :datetime
  end
end
