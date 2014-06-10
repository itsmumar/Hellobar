class LegacyMigrator
  class LegacyUser < LegacyModel
    self.table_name = 'users'

    def id_to_migrate
      legacy_user_id || id
    end
  end
end
