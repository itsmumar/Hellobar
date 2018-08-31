class ChangeDefaultSiteElementToTakeover < ActiveRecord::Migration
  def change
    change_column_default(:site_elements, :type, "Takeover")
  end
end
