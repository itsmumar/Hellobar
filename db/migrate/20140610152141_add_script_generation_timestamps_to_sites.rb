class AddScriptGenerationTimestampsToSites < ActiveRecord::Migration
  def change
    add_column :sites, :script_generated_at, :datetime
    add_column :sites, :script_attempted_to_generate_at, :datetime
  end
end
