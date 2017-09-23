class RemoveUnnecessaryImageUploadsAttributes < ActiveRecord::Migration
  def change
    remove_column :image_uploads, :description, :string, limit: 255
    remove_column :image_uploads, :url, :string, limit: 255
    remove_column :image_uploads, :preuploaded_url, :string, limit: 255
    remove_column :image_uploads, :theme_id, :string, limit: 191
  end
end
