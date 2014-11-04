class LegacyMigrator
  class LegacyAdmin < LegacyModel
    self.table_name = 'admins'

    serialize :valid_access_tokens, Hash
  end
end
