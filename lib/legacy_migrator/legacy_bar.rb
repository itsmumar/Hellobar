class LegacyMigrator
  class LegacyBar < LegacyModel
    self.table_name = 'bars'

    belongs_to :user
    belongs_to :goal

    has_many :bar_stats
  end
end
