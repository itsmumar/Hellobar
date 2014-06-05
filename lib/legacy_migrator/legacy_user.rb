class LegacyMigrator
  class LegacyUser < LegacyModel
    self.table_name = 'users'

    has_many :memberships
    has_many :accounts, through: :memberships
    has_many :user_logins
    has_many :survey_results
  end
end
