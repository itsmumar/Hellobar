class AddDisplayWhenToSiteElements < ActiveRecord::Migration
  def change
    add_column :site_elements, :display_when, :string, :default => "immediately"
  end
end
