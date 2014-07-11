class RemoveUnconfigurableSiteElementColumns < ActiveRecord::Migration
  def change
    remove_column :site_elements, :hide_destination
    remove_column :site_elements, :open_in_new_window
    remove_column :site_elements, :pushes_page_down
    remove_column :site_elements, :remains_at_top
    remove_column :site_elements, :wiggle_wait
    remove_column :site_elements, :tab_side
  end
end
