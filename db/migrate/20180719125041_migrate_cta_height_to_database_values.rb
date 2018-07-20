class MigrateCtaHeightToDatabaseValues < ActiveRecord::Migration
  def up
    # Bars
    SiteElement
      .where(type: 'Bar')
      .update_all(cta_height: 27)

    SiteElement
      .where(type: 'Bar')
      .where(theme_id: 'smooth-impact')
      .update_all(cta_height: 34)

    # Sliders
    SiteElement
      .where(type: 'Slider')
      .update_all(cta_height: 30)

    SiteElement
      .where(type: 'Slider')
      .where(theme_id: 'french-rose')
      .update_all(cta_height: 49)

    SiteElement
      .where(type: 'Slider')
      .where(theme_id: 'green-timberline')
      .update_all(cta_height: 33)

    SiteElement
      .where(type: 'Slider')
      .where(theme_id: 'marigold')
      .update_all(cta_height: 46)

    SiteElement
      .where(type: 'Slider')
      .where(theme_id: 'smooth-impact')
      .update_all(cta_height: 35)

    SiteElement
      .where(type: 'Slider')
      .where(theme_id: 'marigold')
      .update_all(cta_height: 34)
  end
end
