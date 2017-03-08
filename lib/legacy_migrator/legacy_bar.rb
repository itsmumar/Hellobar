class LegacyMigrator
  class LegacyBar < LegacyModel
    self.table_name = 'bars'

    belongs_to :goal, class_name: 'LegacyGoal'

    serialize :settings_json, JSON
  end
end
