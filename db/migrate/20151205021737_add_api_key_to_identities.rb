class AddApiKeyToIdentities < ActiveRecord::Migration
  def change
    add_column :identities, :api_key, :string
  end
end
