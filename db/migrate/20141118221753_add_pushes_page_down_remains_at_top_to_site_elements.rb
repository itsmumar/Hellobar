class AddPushesPageDownRemainsAtTopToSiteElements < ActiveRecord::Migration
  def change
    add_column :site_elements, :pushes_page_down, :boolean, default: true
    add_column :site_elements, :remains_at_top, :boolean, default: true
  end
end
