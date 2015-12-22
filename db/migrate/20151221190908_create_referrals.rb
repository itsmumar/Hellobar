class CreateReferrals < ActiveRecord::Migration
  def change
    create_table :referrals do |t|
      t.references :site, index: true

      t.timestamps
    end
  end
end
