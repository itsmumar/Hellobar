class RenameAndAddNotNullToLead < ActiveRecord::Migration
  def change
    rename_column :leads, :interesting, :interested
    change_column_null :leads, :industry, false
    change_column_null :leads, :interested, false
    change_column_null :leads, :job_role, false
    change_column_null :leads, :company_size, false
    change_column_null :leads, :estimated_monthly_traffic, false
    change_column_null :leads, :first_name, false
    change_column_null :leads, :last_name, false
    change_column_null :leads, :challenge, false
    change_column_null :leads, :user_id, false
  end
end
