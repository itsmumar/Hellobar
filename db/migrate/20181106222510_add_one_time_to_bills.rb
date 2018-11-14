class AddOneTimeToBills < ActiveRecord::Migration
  def change
    add_column :bills, :one_time, :boolean, default: false
  end
end
