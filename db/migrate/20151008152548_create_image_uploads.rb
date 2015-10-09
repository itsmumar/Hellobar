class CreateImageUploads < ActiveRecord::Migration
  def change
    create_table :image_uploads do |t|
      t.belongs_to :site
      t.string :description
      t.string :url
      t.attachment :image

      t.timestamps
    end

    add_reference :site_elements, :image_upload, index: true
    add_column :site_elements, :image_placement, :string, default: 'bottom'
  end
end
