class MigratePausedAt < ActiveRecord::Migration
  def up
    execute 'UPDATE site_elements SET paused_at = updated_at WHERE paused = 1'
  end

  def down
    execute 'UPDATE site_elements SET paused = 1 WHERE paused_at is not null'
  end
end
