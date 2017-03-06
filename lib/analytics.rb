require 'json'

class Analytics
  LOG_FILE = Hellobar::Settings[:analytics_log_file]

  class << self
    def track(target_type, target_id, event_name, props = {})
      props = {} unless props
      # Default :at to now
      props[:at] ||= Time.now
      # If :at is a timestamp convert to a Time object
      props[:at] = Time.at(props[:at]) if props[:at].is_a?(Numeric)
      # Format :at
      props[:at] = props[:at].to_s

      # Set the id
      props[:id] = target_id
      # Format the id to a number if applicable
      props[:id] = props[:id].to_i if props[:id] =~ /^\d+$/

      # Set the table name
      table_name = (target_type.to_s + ' ' + event_name.to_s.underscore).downcase.gsub(/[^a-z0-9]+/, ' ').strip.gsub(/\s/, '_')

      # Set the data
      data = { table_name => props }

      tried_creating_missing_file = false
      begin
        File.open(LOG_FILE, (File::WRONLY | File::APPEND)) { |fp| fp.puts(data.to_json) }
      rescue Errno::ENOENT
        raise if tried_creating_missing_file
        FileUtils.mkdir_p(File.dirname(LOG_FILE))
        FileUtils.touch(LOG_FILE)
        tried_creating_missing_file = true
        retry
      end
    end
  end
end
