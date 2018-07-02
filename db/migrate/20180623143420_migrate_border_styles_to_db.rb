class MigrateBorderStylesToDb < ActiveRecord::Migration
  def up
    SiteElement
      .where(theme_id: 'arctic-facet')
      .update_all(cta_border_radius: 4)

    SiteElement
      .where(theme_id: 'blue-autumn')
      .update_all(cta_border_radius: 7)

    SiteElement
      .where(theme_id: 'blue-avalanche')
      .update_all(cta_border_radius: 7)

    SiteElement
      .where(theme_id: 'classy')
      .update_all(cta_border_radius: 0)

    SiteElement
      .where(theme_id: 'dark-green-spring')
      .update_all(cta_border_radius: 7)

    SiteElement
      .where(theme_id: 'evergreen-meadow')
      .update_all(cta_border_radius: 28)

    SiteElement
      .where(theme_id: 'french-rose')
      .update_all(cta_border_radius: 0)

    SiteElement
      .where(theme_id: 'green-timberline')
      .update_all(cta_border_radius: 7)

    SiteElement
      .where(theme_id: 'marigold')
      .update_all(cta_border_radius: 40)

    SiteElement
      .where(theme_id: 'smooth-impact')
      .update_all(cta_border_radius: 3)

    SiteElement
      .where(theme_id: 'subtle-facet')
      .update_all(cta_border_radius: 4)

    SiteElement
      .where(theme_id: 'violet')
      .update_all(cta_border_radius: 7)
  end
end
