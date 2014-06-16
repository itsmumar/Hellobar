class LegacyMigrator
  class LegacyGoal < LegacyModel
    self.table_name = 'goals'
    self.inheritance_column = nil

    has_many :bars, class_name: 'LegacyMigrator::LegacyBar', foreign_key: 'goal_id'

    serialize :data_json, JSON
  end
end
