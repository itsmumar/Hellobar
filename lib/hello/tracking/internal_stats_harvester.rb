module Hello
  module Tracking
    # The InternalStatsHarvester processes a log file and
    # normalizes the data and stores it into analytics tables
    # into the database
    class InternalStatsHarvester
      def initialize
        @timestamp = Time.now.iso8601
      end

      def self.process_internal_stats
        harvester = self.new
        harvester.run
      end

      # To run we first ensure that there is only one running process. Next, we 
      # move the current file (so no new data can be put into it) to a timestamped
      # file. Then we process all the timestamped files. While processing we wrap
      # everything in a transaction to ensure that if there is an error mid-processing
      # we are not left in an incoherent state.
      def run
        raise AlreadyRunning if already_running?
        begin
          create_lock_file!
          rotate_current_file
          process_files
        ensure
          delete_lock_file!
        end
      end

      def rotate_current_file
        current_stats = Hello::Tracking.internal_stats_file
        return if !File.exists?(current_stats) or File.zero?(current_stats)
        FileUtils.mv(current_stats, Hello::Tracking.internal_stats_file(@timestamp))
      end

      def process_files
        # Get the list of files and sort them
        Dir.glob("#{ Rails.root }/log/#{ Rails.env }-internal-stats-tracking*log").each do |file|
          process_file(file)
        end
      end

      def process_file(file)
        ActiveRecord::Base.transaction do
          read_data(file) do |item|
            item.save # Save each item
          end
        end
        # Remove the file after we process it
        FileUtils.rm(file)
      end

      def lock_file
        File.join(Rails.root,'tmp',"internal-stats-harvester-#{ Rails.env }.lock")
      end

      def already_running?
        File.exists?(lock_file)
      end

      private

      def read_data(file)
        File.open(file, 'r').each do |line|
          data = line.chomp.split(Hello::Tracking::InternalLogger::SEPARATOR) 
          if data[1]
            item = case data[1]
                   when Hello::Tracking::InternalLogger::EVENT
                     InternalEvent.new
                   when Hello::Tracking::InternalLogger::PROP
                     InternalProp.new
                   else
                     raise "Unrecognized item: #{line.inspect}"
                  end
            if item
              item.timestamp = data[0]
              item.target_type = data[2]
              item.target_id = data[3]
              item.name = data[4]
              if item.is_a?(InternalProp)
                item.value = data[5]
              end
              yield(item)
            end
          end
        end
      end

      def create_lock_file!
        FileUtils.mkdir_p File.join(Rails.root,'tmp')
        FileUtils.touch lock_file rescue nil
      end

      def delete_lock_file!
        FileUtils.rm_f lock_file
      end
    end
  end
end
