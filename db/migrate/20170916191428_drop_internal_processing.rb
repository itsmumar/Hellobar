class DropInternalProcessing < ActiveRecord::Migration
  def up
    drop_table :internal_processing
  end
end
