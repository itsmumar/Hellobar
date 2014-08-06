class AddContactListIdToSiteElements < ActiveRecord::Migration
  def change
    add_column :site_elements, :contact_list_id, :integer
    add_index :site_elements, :contact_list_id
  end
end
