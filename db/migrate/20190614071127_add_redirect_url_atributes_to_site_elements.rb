class AddRedirectURLAtributesToSiteElements < ActiveRecord::Migration
  def change
    add_column :site_elements, :use_redirect_url, :boolean, default: false
    add_column :site_elements, :answer1url, :string
    add_column :site_elements, :answer2url, :string
  end
end
