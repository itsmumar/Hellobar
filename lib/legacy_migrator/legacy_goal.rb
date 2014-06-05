class LegacyMigrator
  class LegacyGoal < LegacyModel
    self.table_name = 'goals'

    belongs_to :site

    has_many :bars
    has_many :identity_integrations, as: :integrable
  end
end
