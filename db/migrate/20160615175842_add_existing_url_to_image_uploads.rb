class AddExistingURLToImageUploads < ActiveRecord::Migration
  def change
    add_column :image_uploads, :preuploaded_url, :string
    add_column :image_uploads, :theme_id, :string
    add_index :image_uploads, :theme_id, unique: true
  end
end
