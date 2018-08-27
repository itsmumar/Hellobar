class RemoveDefaultValueFromSiteElement < ActiveRecord::Migration
  def change
    change_column_default(:site_elements, :type, nil)
  end
end
