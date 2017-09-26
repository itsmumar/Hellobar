class RemoveCustomHtmlBells < ActiveRecord::Migration
  def up
    SiteElement.where(type: 'Custom').with_deleted.each do |site_element|
      site_element.really_destroy!
    end
  end
end
