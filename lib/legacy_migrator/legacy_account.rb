class LegacyMigrator
  class LegacyAccount < LegacyModel
    self.table_name = 'accounts'

    has_many :memberships, class_name: 'LegacyMigrator::LegacyMembership', foreign_key: 'account_id'
    has_many :sites, class_name: 'LegacyMigrator::LegacySite', foreign_key: 'account_id'
    has_many :users, through: :memberships
  end
end
