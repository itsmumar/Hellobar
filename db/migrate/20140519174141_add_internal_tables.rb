class AddInternalTables < ActiveRecord::Migration
  def change
    create_table :internal_dimensions do |t|
      t.integer :person_id, :null => false
      t.string :name, :null => false, :default => ""
      t.string :value
      t.integer :timestamp
    end

    add_index :internal_dimensions, [:name, :timestamp]
    add_index :internal_dimensions, [:name, :value]

    create_table :internal_events do |t|
      t.integer :timestamp
      t.string :target_type, :name
      t.string :target_id, :limit => 40
    end

    add_index :internal_events, [:target_type, :name]

    create_table :internal_people do |t|
      t.string :visitor_id, :limit => 40
      t.integer :user_id, :account_id, :first_visited_at, :signed_up_at, :completed_registration_at, :created_first_bar_at, :created_second_bar_at, :received_data_at
    end

    add_index :internal_people, :account_id
    add_index :internal_people, :first_visited_at
    add_index :internal_people, :signed_up_at
    add_index :internal_people, :user_id
    add_index :internal_people, :visitor_id

    create_table :internal_processing do |t|
      t.integer :last_updated_at, :null => false
      t.integer :last_event_processed, :null => false
      t.integer :last_prop_processed, :null => false
      t.integer :last_visitor_user_id_processed, :null => false
    end

    create_table :internal_props do |t|
      t.integer :timestamp
      t.string :target_type, :name, :value
      t.string :target_id, :limit => 40
    end

    add_index :internal_props, [:target_type, :name, :value]

    create_table :internal_reports do |t|
      t.string :name
      t.text :data, :limit => 2147483647
      t.timestamps
    end

    add_index :internal_reports, :name
  end
end
