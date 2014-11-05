class LegacyMigrator
  class LegacyMembership < LegacyModel
    self.table_name = 'memberships'

    belongs_to :user, class_name: 'LegacyUser'
    belongs_to :account, class_name: 'LegacyAccount'
  end
end
