class RemoveCustomHtmlFieldsFromSiteElements < ActiveRecord::Migration
  def change
    remove_column :site_elements, :custom_html, :text
    remove_column :site_elements, :custom_css, :text
    remove_column :site_elements, :custom_js, :text
  end
end
