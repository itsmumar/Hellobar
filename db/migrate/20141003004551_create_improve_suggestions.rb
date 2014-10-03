class CreateImproveSuggestions < ActiveRecord::Migration
  def change
    create_table :improve_suggestions do |t|
      t.belongs_to :site
      t.string :name # key for the suggestion
      t.text :data # JSON hash of cybersource_token, card_number, address, etc
      t.datetime :updated_at
    end
    add_index :improve_suggestions, [:site_id, :name, :updated_at]
  end
end
