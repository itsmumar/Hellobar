class AddShowAfterConvertToSiteElements < ActiveRecord::Migration
  def change
    add_column :site_elements, :show_after_convert, :boolean, default: false
  end
end
