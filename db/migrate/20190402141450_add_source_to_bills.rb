class AddSourceToBills < ActiveRecord::Migration
  def change
    add_column :bills, :source, :string
    Bill.update_all source: Bill::CYBERSOURCE
  end
end
