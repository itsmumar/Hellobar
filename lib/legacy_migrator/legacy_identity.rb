class LegacyMigrator
  class LegacyIdentity < LegacyModel
    self.table_name = 'identities'

    serialize :credentials, JSON
    serialize :extra, JSON
  end
end
