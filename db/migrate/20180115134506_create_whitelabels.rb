class CreateWhitelabels < ActiveRecord::Migration
  def change
    create_table :whitelabels do |t|
      t.string :domain, null: false
      t.string :subdomain, null: false
      t.string :status, null: false, limit: 20, default: Whitelabel::NEW

      t.references :site, null: false

      t.timestamps
    end
  end
end
