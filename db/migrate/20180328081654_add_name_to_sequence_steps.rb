class AddNameToSequenceSteps < ActiveRecord::Migration
  def change
    add_column :sequence_steps, :name, :string
  end
end
