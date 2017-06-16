class AddAuthorizationCodeToBill < ActiveRecord::Migration
  def change
    add_column :bills, :authorization_code, :string
  end
end
