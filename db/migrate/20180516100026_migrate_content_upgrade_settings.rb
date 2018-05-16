class MigrateContentUpgradeSettings < ActiveRecord::Migration
  ATTRIBUTES_TO_MIGRATE = [
    :offer_headline,
    :disclaimer,
    :content_upgrade_title,
    :content_upgrade_url,
    :thank_you_enabled,
    :thank_you_headline,
    :thank_you_subheading,
    :thank_you_cta,
    :thank_you_url
  ]

  class ContentUpgradeStub < ActiveRecord::Base
    self.table_name = :site_elements
    self.inheritance_column = :_type

    has_attached_file :content_upgrade_pdf,
      s3_headers: { 'Content-Disposition' => 'attachment' },
      path: '/content_upgrades/content_upgrade_pdfs/:id_partition/:style/:filename'
  end

  class ContentUpgradeSettingsStub < ActiveRecord::Base
    self.table_name = :content_upgrade_settings

    has_attached_file :content_upgrade_pdf,
      s3_headers: { 'Content-Disposition' => 'attachment' },
      path: '/content_upgrade_settings/content_upgrade_pdfs/:id_partition/:style/:filename'
  end

  def up
    ContentUpgradeStub.where(type: 'ContentUpgrade').find_each do |content_upgrade|
      settings = ContentUpgradeSettingsStub.new(content_upgrade_id: content_upgrade.id)
      settings.assign_attributes(content_upgrade.attributes.symbolize_keys.slice(*ATTRIBUTES_TO_MIGRATE))
      settings.content_upgrade_pdf = content_upgrade.content_upgrade_pdf
      settings.save!
    end
  end

  def down
    ContentUpgradeSettingsStub.find_each do |settings|
      content_upgrade = ContentUpgradeStub.find(settings.content_upgrade_id)
      content_upgrade.assign_attributes(settings.attributes.symbolize_keys.slice(*ATTRIBUTES_TO_MIGRATE))
      content_upgrade.content_upgrade_pdf = settings.content_upgrade_pdf
      content_upgrade.save!
    end
  end
end
