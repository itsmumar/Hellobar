class CreateSiteMemberships < ActiveRecord::Migration
  def change
    create_table :site_memberships do |t|
      t.integer :user_id, :site_id
      t.string :role, :default => "owner"

      t.timestamps
    end

    add_index :site_memberships, :user_id
    add_index :site_memberships, :site_id
  end
end
