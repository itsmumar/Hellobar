class AddTimestampsToConditionsEvenThoughItsNotNecessary < ActiveRecord::Migration
  def change
    add_column :conditions, :created_at, :datetime
    add_column :conditions, :updated_at, :datetime
  end
end
