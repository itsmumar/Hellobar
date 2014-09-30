class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.belongs_to :user
      t.belongs_to :site
      t.string :type
      t.integer :schedule, :default => 0
      t.decimal :amount, :scale=>2, :precision=>7
      t.integer :_visit_overage, :default => nil
      t.integer :_visit_overage_unit, :default => nil
      t.decimal :_visit_overage_amount, :scale=>2, :precision=>5
      t.datetime :created_at
    end
  end
end
