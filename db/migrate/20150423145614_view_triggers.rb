class ViewTriggers < ActiveRecord::Migration
  def change

    add_column :site_elements, :view_condition, :string, :default => "immediately"

  end
end
