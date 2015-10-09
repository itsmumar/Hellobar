class UpdateImageUploads < ActiveRecord::Migration
  def change
    remove_reference(:image_uploads, :site, index: true)
    add_reference(:image_uploads, :site_element, index: true)
    add_column :site_elements, :active_image_id, :integer, index: true
  end
end
