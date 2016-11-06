class AddBlocksToSiteElement < ActiveRecord::Migration
  def up
    add_column :site_elements, :blocks, :text

    SiteElement.find_each do |site_element|
      headline = site_element.headline

      unless headline.include?("<p><strong>")
        headline = "<p><strong>#{site_element.headline}</strong></p>"

        # Skip callbacks & script regeneration here.
        site_element.update_column(:headline, headline)
      end
    end
  end

  def down
    remove_column :site_elements, :blocks, :text

    SiteElement.find_each do |site_element|
      headline = site_element.headline

      if headline.include?("<p><strong>")
        headline.slice!("<p><strong>")
        headline.slice!("</strong></p>")

        # Skip callbacks & script regeneration here.
        site_element.update_column(:headline, headline)
      end
    end
  end
end
