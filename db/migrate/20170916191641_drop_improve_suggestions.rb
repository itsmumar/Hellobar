class DropImproveSuggestions < ActiveRecord::Migration
  def up
    drop_table :improve_suggestions
  end
end
