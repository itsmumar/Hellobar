class RemoveCtaBorderColumn < ActiveRecord::Migration
  def change
    remove_column :site_elements, :cta_border, :boolean
  end
end
