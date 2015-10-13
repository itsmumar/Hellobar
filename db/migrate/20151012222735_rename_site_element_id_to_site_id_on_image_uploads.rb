class RenameSiteElementIdToSiteIdOnImageUploads < ActiveRecord::Migration
  def change
    rename_column :image_uploads, :site_element_id, :site_id

  end
end
