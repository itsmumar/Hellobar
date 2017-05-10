require 'json'

class Analytics
  LOG_FILE = Rails.root.join 'log', 'analytics.log'

  class << self
    def segment
      @segment ||= Segment::Analytics.new(write_key: Settings.segment_key, stub: Rails.env.test?)
    end

    def alias(visitor_id, user_id)
      track_internal :visitor, visitor_id, :user_id, value: user.id
      segment.alias(previous_id: visitor_id, user_id: user_id)
    end

    def track(target_type, target_id, event_name, props = {})
      track_internal target_type, target_id, event_name, props
      track_segment target_type, target_id, event_name, props
    end

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

    def track_segment(target_type, target_id, event_name, props)
      attributes = { event: event_name, properties: props }
      attributes[:user_id] = target_id if target_type == :user
      attributes[:anonymous_id] = target_id if target_type == :visitor

      if target_type == :site
        attributes = attributes.merge(site_id: target_id, anonymous_id: "anonymous site #{ target_id }")
      end

      segment.track attributes
    end
  end
end
