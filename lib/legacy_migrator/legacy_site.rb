class LegacyMigrator
  class LegacySite < LegacyModel
    self.table_name = 'sites'

    belongs_to :account

    has_many :goals
    has_many :bars, through: :goals
    has_many :identities
    has_many :identity_integrations, as: :integrable
  end
end
