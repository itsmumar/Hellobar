class LegacyMigrator
  class LegacyGoal < LegacyModel
    self.table_name = 'goals'
    self.inheritance_column = nil

    belongs_to :site, class_name: 'LegacySite'

    has_many :bars, class_name: 'LegacyMigrator::LegacyBar', foreign_key: 'goal_id'

    serialize :data_json, JSON

    def priority; 1; end
  end
end
