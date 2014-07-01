class CreateIdentities < ActiveRecord::Migration
  def change
    create_table :identities do |t|
      t.integer :site_id
      t.string :provider
      t.text :credentials, :extra, :embed_code

      t.timestamps
    end
  end
end
