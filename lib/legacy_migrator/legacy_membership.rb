class LegacyMigrator
  class LegacyMembership < LegacyModel
    self.table_name = 'memberships'

    belongs_to :user, class_name: 'LegacyUser'
  end
end
