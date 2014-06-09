class LegacyMigrator
  class LegacyGoal < LegacyModel
    self.table_name = 'goals'
    self.inheritance_column = nil
  end
end
