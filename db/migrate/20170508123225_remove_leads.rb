class RemoveLeads < ActiveRecord::Migration
  def change
    drop_table :leads do |t|
      t.string :industry, null: false
      t.string :job_role, null: false
      t.string :company_size, null: false
      t.string :estimated_monthly_traffic, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :challenge, null: false
      t.boolean :interested, index: true, null: false
      t.string :phone_number
      t.belongs_to :user, index: true, null: false

      t.timestamps
    end
  end
end
