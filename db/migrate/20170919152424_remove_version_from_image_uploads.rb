class RemoveVersionFromImageUploads < ActiveRecord::Migration
  def up
    remove_index :image_uploads, :version
    remove_column :image_uploads, :version
  end

  def down
    add_column :image_uploads, :version, :integer, default: 1
    add_index :image_uploads, :version
  end
end
