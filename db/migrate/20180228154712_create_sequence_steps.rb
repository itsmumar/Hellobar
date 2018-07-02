class CreateSequenceSteps < ActiveRecord::Migration
  def change
    create_table :sequence_steps do |t|
      t.integer :delay, null: false, default: 0

      t.references :sequence, index: true, null: false
      t.references :executable, polymorphic: true, index: true, null: false

      t.datetime :deleted_at

      t.timestamps
    end
  end
end
