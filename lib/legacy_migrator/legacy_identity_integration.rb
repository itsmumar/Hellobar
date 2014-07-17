class LegacyMigrator
  class LegacyIdentityIntegration < LegacyModel
    self.table_name = 'identity_integrations'

    serialize :data, JSON
  end
end
