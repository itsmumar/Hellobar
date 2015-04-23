class ViewTriggers < ActiveRecord::Migration
  def change

    add_column :site_elements, :view_condition, :string
    add_column :site_elements, :view_condition_attribute, :integer

  end
end
