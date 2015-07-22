class LocalizePlaceholders < ActiveRecord::Migration
  def change

    add_column :site_elements, :email_placeholder, :string, null: false, default: "Your email"
    add_column :site_elements, :name_placeholder, :string, null: false, default: "Your name"

  end
end
