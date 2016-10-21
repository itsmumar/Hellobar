class DropShowAfterConvertFromSiteElement < ActiveRecord::Migration
  def self.up
    remove_column :site_elements, :show_after_convert
  end

  def self.down
    add_column :site_elements, :show_after_convert, :boolean, default: false
  end
end
