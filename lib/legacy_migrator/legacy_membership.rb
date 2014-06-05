class LegacyMigrator
  class LegacyMembership < LegacyModel
    self.table_name = 'memberships'

    belongs_to :account
    belongs_to :user
  end
end
