module Hello
  module Tracking

    class InternalLogger
      SEPARATOR = "\t"
      EVENT = "E"
      PROP = "P"

      def format_message(severity, timestamp, progname, msg)
        line = "#{ timestamp.to_i }#{SEPARATOR}#{msg}\n"
        print "logging: "+line
        line
      end
    end

    def self.internal_stats_file(date=nil)
      date += "." if date.present?
      "#{ Rails.root }/log/#{ Rails.env }-internal-stats-tracking.#{date}log"
    end

    def self.write(message)
      File.open(internal_stats_file, "a") do |fp|
        fp.sync = true
        fp.puts(message)
      end
    end

    def self.create_events_endpoint
      @events ||= EventEndpoint.new
    end

    def self.create_props_endpoint
      @props ||= PropEndpoint.new
    end

    def self.track_event(target_type, id, event_name)
      write([Time.now.to_i, InternalLogger::EVENT, target_type, id, event_name].join(InternalLogger::SEPARATOR))
    end

    def self.track_prop(target_type, id, prop_name, prop_value)
      write([Time.now.to_i, InternalLogger::PROP, target_type, id, prop_name, prop_value].join(InternalLogger::SEPARATOR))
    end

    class EventEndpoint
      attr_accessor :response, :request

      def initialize(options={})
        @response = {ok:"true"}
      end

      def call(env)
        if path = env['REQUEST_PATH']
          path = path.gsub(/^\//, "").split('/')
          path.map! {|v| Rack::Utils.unescape(v) }
          path.reject! {|v| v == "did" || v == "" }

          Hello::Tracking.track_event(*path)
        end

        [200,{"Content-Type"=>"application/json"},[JSON.generate(response)]]
      end
    end

    class PropEndpoint
      attr_accessor :response, :request

      def initialize(options={})
        @response = {ok:"true"}
      end

      def call(env)
        if path = env['REQUEST_PATH']
          path = path.gsub(/^\//, "").split('/')
          path.map! {|v| Rack::Utils.unescape(v) }
          path.reject! {|v| v == "has" || v == "of"}

          Hello::Tracking.track_prop(*path)
        end

        [200,{"Content-Type"=>"application/json"},[JSON.generate(response)]]
      end
    end
  end
end
