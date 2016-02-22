class AddPhoneCountryCodeToSiteElement < ActiveRecord::Migration
  def change
    add_column :site_elements, :phone_country_code, :string, default: "US"
  end
end
