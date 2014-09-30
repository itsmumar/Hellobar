class BillEndsDateToEndDate < ActiveRecord::Migration
  def change
    rename_column :bills, :ends_date, :end_date
  end
end
