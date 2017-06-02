class RenameContentUpgradeTitleAndURL < ActiveRecord::Migration
  def change
    rename_column :site_elements, :title, :content_upgrade_title
    rename_column :site_elements, :url, :content_upgrade_url
  end
end
