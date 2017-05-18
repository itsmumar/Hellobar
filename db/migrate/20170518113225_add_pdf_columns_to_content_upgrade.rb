class AddPdfColumnsToContentUpgrade < ActiveRecord::Migration
  def up
    add_attachment :site_elements, :content_upgrade_pdf
  end

  def down
    remove_attachment :site_elements, :content_upgrade_pdf
  end
end
