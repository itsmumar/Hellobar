class DropLegacyBarColumns < ActiveRecord::Migration
  def change
    remove_column :site_elements, :show_wait
    remove_column :site_elements, :hide_after
  end
end
