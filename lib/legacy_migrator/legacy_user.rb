class LegacyMigrator
  class LegacyUser < LegacyModel
    self.table_name = 'users'

    has_many :memberships, class_name: 'LegacyMembership', foreign_key: 'user_id'
    has_many :accounts, :through => :memberships

    def id_to_migrate
      legacy_user_id || id
    end
  end
end
