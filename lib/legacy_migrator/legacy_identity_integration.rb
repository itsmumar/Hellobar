class LegacyMigrator
  class LegacyIdentityIntegration < LegacyModel
    self.table_name = 'identity_integrations'

    belongs_to :identity, class_name: 'LegacyMigrator::LegacyIdentity'

    serialize :data, JSON
  end
end
