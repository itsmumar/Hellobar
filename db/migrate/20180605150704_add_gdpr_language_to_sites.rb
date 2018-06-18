class AddGdprLanguageToSites < ActiveRecord::Migration
  def change
    add_column :sites, :gdpr_consent_language, :string, limit: 10, default: 'en'
  end
end
