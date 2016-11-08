class AlterColumnHeadlineAndCaptionInSiteElement < ActiveRecord::Migration
  def up
  	change_table :site_elements do |t|
      t.change :headline, :string, default: nil
      t.change :caption, :string, default: nil
      t.change :headline, :text, limit: 65536
      t.change :caption, :text, limit: 65536
      # 
      SiteElement.find_each do |site_element|
        caption = site_element.caption
        headline  = site_element.headline # So that setter function sanitizes the value
        attrs     = { headline: headline, caption: caption }
        # Skip callbacks & script regeneration here.
        SiteElement.where(id: site_element.id).update_all(attrs)
      end
    end
  end

  def down
  	change_table :site_elements do |t|
      t.change :headline, :string, default: 'Hello. Add your message here.'
      t.change :caption, :string, default: ''
    end
  end
end
