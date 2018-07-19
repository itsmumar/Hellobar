class MigrateCtaHeightToDatabaseValues < ActiveRecord::Migration
  def up
    SiteElement
      .where(type: 'Bar')
      .update_all(cta_height: 27)

    SiteElement
      .where(type: 'Bar')
      .where(theme_id: 'smooth-impact')
      .update_all(cta_height: 34)
  end
end
