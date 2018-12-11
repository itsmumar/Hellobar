class AddViewCountToBills < ActiveRecord::Migration
  def change
    add_column :bills, :view_count, :integer
  end
end
