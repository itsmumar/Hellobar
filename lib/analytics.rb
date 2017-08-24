require 'json'

class Analytics
  LOG_FILE = Rails.root.join 'log', 'analytics.log'

  class << self
    def log_file
      LOG_FILE
    end

    def alias(visitor_id, user_id)
      track_internal :visitor, visitor_id, :user_id, value: user_id
    end

    def track(target_type, target_id, event_name, props = {})
      track_internal target_type, target_id, event_name, props
    end

    private

    def track_internal(target_type, target_id, event_name, props = {})
      props = {} unless props
      # Default :at to now
      props[:at] ||= Time.current
      # If :at is a timestamp convert to a Time object
      props[:at] = Time.zone.at(props[:at]) if props[:at].is_a?(Numeric)
      # Format :at
      props[:at] = props[:at].to_s

      # Set the id
      props[:id] = target_id
      # Format the id to a number if applicable
      props[:id] = props[:id].to_i if props[:id] =~ /^\d+$/

      # Set the table name
      table_name = (target_type.to_s + ' ' + event_name.to_s.underscore).downcase.gsub(/[^a-z0-9]+/, ' ').strip.gsub(/\s/, '_')

      write_data table_name => props
    end

    def write_data(data)
      make_sure_file_exist
      log_file.open(File::WRONLY | File::APPEND) { |f| f.puts data.to_json }
    end

    def make_sure_file_exist
      return if log_file.exist?
      log_file.dirname.mkpath
      log_file.binwrite ''
    end
  end
end
