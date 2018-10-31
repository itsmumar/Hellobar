class AddOptionalCaptionAndOptionalContentToSiteElement < ActiveRecord::Migration
  def change
    add_column :site_elements, :show_optional_caption, :boolean, null: false, default: true
  end
end
