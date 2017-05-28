class AddVersionToImageUploads < ActiveRecord::Migration
  def change
    add_column :image_uploads, :version, :integer, default: 1
    add_index :image_uploads, :version
  end
end
