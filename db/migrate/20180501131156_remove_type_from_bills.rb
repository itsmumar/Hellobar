class RemoveTypeFromBills < ActiveRecord::Migration
  def up
    remove_column :bills, :type
  end

  def down
    add_column :bills, :type, :string
    connection.execute "update `bills` set `type`='Bill::Recurring'"
  end
end
