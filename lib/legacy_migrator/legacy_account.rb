class LegacyMigrator
  class LegacyAccount < LegacyModel
    self.table_name = 'accounts'

    has_many :memberships, class_name: 'LegacyMigrator::LegacyMembership', foreign_key: 'account_id'
  end
end
