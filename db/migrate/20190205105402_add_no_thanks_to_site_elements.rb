class AddNoThanksToSiteElements < ActiveRecord::Migration
  def change
    add_column :site_elements, :no_thanks_text, :string, default: 'No, Thanks'
    add_column :site_elements, :show_no_thanks, :boolean, default: true
    SiteElement.update_all(show_no_thanks: false)
  end

end
