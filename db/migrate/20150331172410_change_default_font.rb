class ChangeDefaultFont < ActiveRecord::Migration
  def up
    change_column :site_elements, :font, :string, :default => "'Open Sans',sans-serif"
  end

  def down
    change_column :site_elements, :font, :string, :default => "Helvetica,Arial,sans-serif"
  end
end
