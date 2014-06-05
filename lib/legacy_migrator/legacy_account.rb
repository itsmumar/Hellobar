class LegacyMigrator
  class LegacyAccount < LegacyModel
    self.table_name = 'accounts'

    has_many :memberships
    has_many :users, through: :memberships
    has_many :sites
    has_many :goals, through: :sites
    has_many :identities, through: :sites
    has_many :bars, through: :goals
    has_many :survey_results
  end
end
