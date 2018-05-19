class MigrateContentUpgradesStyles < ActiveRecord::Migration
  class SiteStub < ActiveRecord::Base
    self.table_name = :sites

    store :settings, coder: JSON
  end

  class ContentUpgradeStylesStub < ActiveRecord::Base
    self.table_name = :content_upgrade_styles
  end

  NON_STYLE_ATTRIBUTES = %w[id site_id created_at updated_at]
  STYLE_ATTRIBUTES = ContentUpgradeStylesStub.column_names - NON_STYLE_ATTRIBUTES

  def up
    SiteStub.find_each do |site|
      next if site.settings['content_upgrade'].blank?

      styles = site.settings['content_upgrade'].stringify_keys.slice(*STYLE_ATTRIBUTES)
      ContentUpgradeStylesStub.create!({ site_id: site.id }.merge(styles))
    end

    puts "#{ContentUpgradeStylesStub.count} records migrated"
  end

  def down
    ContentUpgradeStylesStub.find_each do |styles|
      site = SiteStub.find(styles.site_id)
      site.settings['content_upgrade'] = styles.attributes.except(*NON_STYLE_ATTRIBUTES)
      site.save!
    end
  end
end
