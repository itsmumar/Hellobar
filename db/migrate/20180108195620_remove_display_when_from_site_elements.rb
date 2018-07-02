class RemoveDisplayWhenFromSiteElements < ActiveRecord::Migration
  def change
    remove_column :site_elements, :display_when, :string, limit: 255, default: 'immediately'
  end
end
