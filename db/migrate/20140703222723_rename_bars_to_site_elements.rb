class RenameBarsToSiteElements < ActiveRecord::Migration
  def change
    rename_table :bars, :site_elements
  end
end
