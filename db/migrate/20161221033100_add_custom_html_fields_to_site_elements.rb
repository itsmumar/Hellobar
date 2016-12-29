class AddCustomHtmlFieldsToSiteElements < ActiveRecord::Migration
  def change
    add_column :site_elements, :custom_html, :text
    add_column :site_elements, :custom_css, :text
    add_column :site_elements, :custom_js, :text
  end
end
