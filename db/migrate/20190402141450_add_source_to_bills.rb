class AddSourceToBills < ActiveRecord::Migration
  CYBERSOURCE = 'cybersource'.freeze

  def change
    add_column :bills, :source, :string
    Bill.update_all source: CYBERSOURCE
  end
end
