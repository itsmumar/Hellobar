class DefaultCaptionToEmptyString < ActiveRecord::Migration
  def change
    change_column :site_elements, :caption, :string, :default => ''
  end
end
