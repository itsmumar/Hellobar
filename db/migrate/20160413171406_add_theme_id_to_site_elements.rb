class AddThemeIdToSiteElements < ActiveRecord::Migration
  def up
    add_column :site_elements, :theme_id, :string

    SiteElement.update_all(theme_id: "classic")
  end

  def down
    remove_column :site_elements, :theme_id
  end
end
