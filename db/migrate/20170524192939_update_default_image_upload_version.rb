class UpdateDefaultImageUploadVersion < ActiveRecord::Migration
  def up
    change_column_default(:image_uploads, :version, 2)
  end

  def down
    change_column_default(:image_uploads, :version, 1)
  end
end
