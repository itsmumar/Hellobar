class RemoveImageUploadIdFromSiteElements < ActiveRecord::Migration
  def change
    remove_column :site_elements, :image_upload_id, :integer, limit: 4
  end
end
