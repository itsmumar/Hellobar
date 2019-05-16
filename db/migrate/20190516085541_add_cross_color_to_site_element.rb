class AddCrossColorToSiteElement < ActiveRecord::Migration
  def change
    add_column :site_elements, :cross_color, :string, default: 'ffffff', null: false
  end
end
