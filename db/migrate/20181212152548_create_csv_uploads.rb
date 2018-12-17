class CreateCsvUploads < ActiveRecord::Migration
  def change
    create_table :csv_uploads do |t|
      t.belongs_to :contact_list, index: true
      t.attachment :csv

      t.timestamps
    end
  end
end
