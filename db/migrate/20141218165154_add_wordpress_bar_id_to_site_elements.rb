class AddWordpressBarIdToSiteElements < ActiveRecord::Migration
  def change
    add_column :site_elements, :wordpress_bar_id, :integer
  end
end
