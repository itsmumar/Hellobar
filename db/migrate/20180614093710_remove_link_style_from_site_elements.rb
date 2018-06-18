class RemoveLinkStyleFromSiteElements < ActiveRecord::Migration
  def change
    remove_column :site_elements, :link_style, :string, default: 'button'
  end
end
