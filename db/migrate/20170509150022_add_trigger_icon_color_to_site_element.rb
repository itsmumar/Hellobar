class AddTriggerIconColorToSiteElement < ActiveRecord::Migration
  def change
    add_column :site_elements, :trigger_icon_color, :string, default: 'ffffff', null: false
  end
end
