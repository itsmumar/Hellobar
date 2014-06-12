class LegacyMigrator
  module DateTimeConverter
    def convert_start_time(date, timezone)
      return nil if date.blank?

      DateTime.parse "#{date} 00:00:00 #{timezone}"
    end

    def convert_end_time(date, timezone)
      return nil if date.blank?

      DateTime.parse "#{date} 23:59:59 #{timezone}"
    end
  end
end
