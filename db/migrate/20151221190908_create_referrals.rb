class CreateReferrals < ActiveRecord::Migration
  def change
    create_table :referrals do |t|
      t.references :user, index: true

      t.timestamps
    end
  end
end
