class CreateLeads < ActiveRecord::Migration
  def change
    create_table :leads do |t|
      t.string :industry
      t.string :job_role
      t.string :company_size
      t.string :estimated_monthly_traffic
      t.string :first_name
      t.string :last_name
      t.string :challenge
      t.boolean :interesting, index: true
      t.string :phone_number
      t.belongs_to :user, index: true


      t.timestamps
    end
  end
end
