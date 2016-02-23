class AddPhoneToSiteElements < ActiveRecord::Migration
  def change
    add_column :site_elements, :phone_number, :string
  end
end
