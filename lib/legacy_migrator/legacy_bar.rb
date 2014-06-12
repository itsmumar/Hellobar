class LegacyMigrator
  class LegacyBar < LegacyModel
    self.table_name = 'bars'

    serialize :settings_json, JSON
  end
end
