class LegacyMigrator
  class LegacySite < LegacyModel
    self.table_name = 'sites'

    belongs_to :account, class_name: 'LegacyAccount'

    has_many :goals, class_name: 'LegacyGoal', foreign_key: 'site_id'

    serialize :settings_json, JSON
  end
end
