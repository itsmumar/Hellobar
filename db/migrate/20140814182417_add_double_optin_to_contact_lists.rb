class AddDoubleOptinToContactLists < ActiveRecord::Migration
  def change
    add_column :contact_lists, :double_optin, :boolean, :default => true
  end
end
