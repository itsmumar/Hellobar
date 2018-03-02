class RemoveEmailAttributesFromCampaigns < ActiveRecord::Migration
  def change
    remove_column :campaigns, :from_name, :string, null: false, after: :name
    remove_column :campaigns, :from_email, :string, null: false, after: :name
    remove_column :campaigns, :subject, :string, null: false, after: :name
    remove_column :campaigns, :body, :text, null: false, after: :name
  end
end
