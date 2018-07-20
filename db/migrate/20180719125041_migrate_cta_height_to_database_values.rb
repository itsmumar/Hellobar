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

    # Sliders
    SiteElement
      .where(type: 'Modal')
      .update_all(cta_height: 41)

    SiteElement
      .where(type: 'Modal')
      .where(theme_id: 'classic')
      .update_all(cta_height: 38)

    SiteElement
      .where(type: 'Modal')
      .where(theme_id: 'french-rose')
      .update_all(cta_height: 71)

    SiteElement
      .where(type: 'Modal')
      .where(theme_id: 'marigold')
      .update_all(cta_height: 71)

    SiteElement
      .where(type: 'Modal')
      .where(theme_id: 'smooth-impact')
      .update_all(cta_height: 42)

    # Page Takeovers
    SiteElement
      .where(type: 'Takeover')
      .update_all(cta_height: 57)

    SiteElement
      .where(type: 'Takeover')
      .where(theme_id: 'arctic-facet')
      .update_all(cta_height: 66)

    SiteElement
      .where(type: 'Takeover')
      .where(theme_id: 'french-rose')
      .update_all(cta_height: 79)

    SiteElement
      .where(type: 'Takeover')
      .where(theme_id: 'marigold')
      .update_all(cta_height: 79)

    SiteElement
      .where(type: 'Takeover')
      .where(theme_id: 'smooth-impact')
      .update_all(cta_height: 76)

    SiteElement
      .where(type: 'Takeover')
      .where(theme_id: 'smooth-impact')
      .update_all(cta_height: 66)
  end
end
