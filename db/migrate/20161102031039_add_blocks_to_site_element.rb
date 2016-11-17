class AddBlocksToSiteElement < ActiveRecord::Migration
  THEME_IDS = ["green-timberline", "blue-autumn", "french-rose", "violet",
               "dark-green-spring", "marigold"]
  BAR_THEMES = ["classy", "hellobar-classic"]
  OPEN_TAGS = "<p><strong>"
  CLOSE_TAGS = "</strong></p>"

  def up
    add_column :site_elements, :blocks, :text

    # Update existing data to support floala editor
    SiteElement.find_each do |site_element|
      link_text = site_element.link_text
      headline  = add_tags(site_element.headline)
      link_text = add_tags(link_text) if theme_condition_satisfied?(site_element)
      attrs     = { headline: headline, link_text: link_text }

      # Skip callbacks & script regeneration here.
      SiteElement.where(id: site_element.id).update_all(attrs)
    end
  end

  def down
    remove_column :site_elements, :blocks, :text

    # Update existing data to remove support floala editor
    SiteElement.find_each do |site_element|
      link_text = site_element.link_text
      headline  = remove_tags(site_element.headline)
      link_text = remove_tags(link_text) if theme_condition_satisfied?(site_element)
      attrs     = { headline: headline, link_text: link_text }

      # Skip callbacks & script regeneration here.
      SiteElement.where(id: site_element.id).update_all(attrs)
    end
  end

  def add_tags(text)
    if Rails.env.production? || (!text.include?("<p>") && !text.include?(OPEN_TAGS))
      "#{OPEN_TAGS}#{text}#{CLOSE_TAGS}"
    else
      text
    end
  end

  def remove_tags(text)
    text.slice!(OPEN_TAGS)
    text.slice!(CLOSE_TAGS)

    text
  end

  def theme_condition_satisfied?(site_element)
    THEME_IDS.include?(site_element.theme_id) ||
                                  (BAR_THEMES.include?(site_element.theme_id) &&
                                    site_element.type == 'Bar')
  end
end
