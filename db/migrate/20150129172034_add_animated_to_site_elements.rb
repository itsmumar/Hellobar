class AddAnimatedToSiteElements < ActiveRecord::Migration
  def change
    add_column :site_elements, :animated, :boolean, default: false
  end
end
