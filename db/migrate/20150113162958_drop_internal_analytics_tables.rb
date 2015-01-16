class DropInternalAnalyticsTables < ActiveRecord::Migration
  def up
    drop_table :internal_dimensions
    drop_table :internal_events
    drop_table :internal_people
    drop_table :internal_props
    drop_table :internal_reports
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
