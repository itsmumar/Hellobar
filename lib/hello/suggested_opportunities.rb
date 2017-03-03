require 'aws-sdk'

module Hello
  class DynamoDB
    # Used for storing combined conversions and views
    CONVERSION_SCALE = 10_000_000

    class << self
      def setup
        connect
        load_tables
      end

      # Returns the total amounts for all segments for the given start_date
      # and end_date for the given site_element_ids in the format:
      # {
      #   segment => [num_views_week, num_conversions_week],
      #   segment2 => [num_views_week, num_conversions_week],
      #   ...
      # }
      def get_segments_by_week(site_element_ids, start_date, end_date, segment_keys)
        # Query every site element id
        final_results = Hash.new{|h, k| h[k]= [0,0]}
        site_element_ids.each do |site_element_id|
          results_for_site_element = Hash.new{|h, k| h[k] = {total: 0, min_yday: nil, max_yday: nil}}
          # We need to query every table for the given start date and end date
          ydays_by_year_month(start_date, end_date).each do |year_month, ydays|
            year_offset = (year_month.split("_").first.to_i-2000)*365
            # Get the table
            table = get_segments_table_for_year_month(year_month)
            begin
              segment_keys.each do |segment_key|
                table.items.query(
                  hash_value: site_element_id,
                  range_begins_with: segment_key,
                  select: [:segment]+ydays
                ).each do |item|
                  segment = item.attributes["segment"]
                  result = results_for_site_element[segment]
                  item.attributes.each do |key, value|
                    unless key == "segment"
                      yday = key.to_i + year_offset
                      result[:total] += value.to_i
                      result[:min_yday] = yday if !result[:min_yday] or yday < result[:min_yday]
                      result[:max_yday] = yday if !result[:max_yday] or yday > result[:max_yday]
                    end
                  end
                end
              end
            rescue AWS::DynamoDB::Errors::ResourceNotFoundException => e
              # Table doesn't exist - just ignore
            end
          end
          # Now we need to calculate the average value for each and add it to the final results
          results_for_site_element.each do |segment, data|
            total = data[:total]
            if total > 0
              conversions = (total/CONVERSION_SCALE)
              views = total-(conversions*CONVERSION_SCALE)
              num_weeks = (((data[:max_yday]-data[:min_yday]).to_f+1)/7)
              conversions = (conversions/num_weeks).round
              views = (views/num_weeks).round
              final_results[segment][0] += views
              final_results[segment][1] += conversions
            end
          end
        end
        return final_results
      end

      # For the given start date and end date returns a hash where the
      # key is the year month (e.g. "2014_9") and the value is an array
      # of ydays that fall in that month (e.g. [245,246,...]). This
      # is used by get_segments
      def ydays_by_year_month(start_date, end_date)
        date = start_date
        day = 24*60*60
        results = Hash.new{|h,k| h[k] = []}
        loop do
          results["#{date.year}_#{date.month}"] << date.yday
          date += day
          break if date > end_date
        end
        return results
      end

      # Returns the actual table name based for the given key.
      def table_name(key)
        key = key.to_s
        if %w{contacts over_time segments}.include?(key)
          return key
        else
          raise "Unknown table name key #{key.inspect}"
        end
      end

      def tables
        @@tables
      end

      # Returns the segment table name for the given date
      def segment_table_name(date)
        segment_table_name_for_year_month("#{date.year}_#{date.month}")
      end

      # Returns the segment table name for the given year and month (e.g. "2014_9")
      def segment_table_name_for_year_month(year_month)
        table_name(:segments)+"_#{year_month}"
      end

      protected

      def connect
        AWS.config(
          :access_key_id => Hellobar::Settings[:aws_access_key_id],
          :secret_access_key => Hellobar::Settings[:aws_secret_access_key]
        )
        # We use both the "friendly" interface (@@dynamo_db) and the
        # direct interface (@@client)
        @@dynamo_db = AWS::DynamoDB.new
        @@client = AWS::DynamoDB::Client.new(api_version: '2012-08-10')
      end

      def load_tables
        # Load the table schemas
        @@tables = {}
        load_table(:contacts, {lid: :number}, {email: :string})
        load_table(:over_time, {sid: :number}, {date: :number})
      end

      def load_table(name, hash_key, range_key)
        table = @@dynamo_db.tables[table_name(name)]
        table.hash_key = hash_key
        table.range_key = range_key
        @@tables[name] = table
      end

      def get_segments_table(date)
        get_segments_table_for_year_month("#{date.year}_#{date.month}")
      end

      def get_segments_table_for_year_month(year_month)
        # Segment tables are broken up by year and month
        name = segment_table_name_for_year_month(year_month)
        unless @@tables[name]
          table = @@dynamo_db.tables[name]
          table.hash_key = {sid: :number}
          table.range_key = {segment: :string}
          @@tables[name] = table
        end
        return @@tables[name]
      end
    end
  end

  class SuggestedOpportunities
    SUGGESTION_SEGMENT_KEYS = %w{dv st rd pu}

    class << self
      def generate(site, site_elements)
        # Get all the segments for the last 60 days for all the site
        # elements
        end_date = Time.now
        start_date = end_date-60*24*60*60
        # Get the segments by week
        segments_as_hash = Hello::DynamoDB.get_segments_by_week(site_elements.collect(&:id), start_date, end_date, SUGGESTION_SEGMENT_KEYS)
        segments = []
        # Convert to array
        segments_as_hash.each do |segment, data|
          segments << [segment, data[0], data[1]]
        end
        # We return 10 values or 25% of the items, whichever is smaller
        num_values_to_return = [10, (segments.length.to_f/4).round].min
        # Sort the segment-values by total visits desc (most visits is at top)
        segments.sort!{|a, b| b[1] <=> a[1]}
        # Take the top 25% of segments. If less than 80 item take top 50%
        top_segments = nil
        bottom_segments = nil
        if segments.length < 80
          # Top 50%
          top_segments = segments[0...segments.length/2]
          # Bottom 50%
          bottom_segments = segments[segments.length/2..-1]
        else
          # Top 25%
          top_segments = segments[0...segments.length/4]
          # Bottom 50%
          bottom_segments = segments[segments.length/2..-1]
        end
        # Define sort methods
        sort_by_conversion_rate = lambda do |a,b|
          conv_a = a[1] == 0 ? 0 : a[2].to_f/a[1]
          conv_b = b[1] == 0 ? 0 : b[2].to_f/b[1]
          conv_b <=> conv_a
        end
        sort_by_conversion = lambda do |a,b|
          if b[2] == a[2]
            conv_a = a[1] == 0 ? 0 : a[2].to_f/a[1]
            conv_b = b[1] == 0 ? 0 : b[2].to_f/b[1]
            conv_b <=> conv_a
          else
            b[2] <=> a[2]
          end
        end
        # Sort by conversion rate desc
        top_segments.sort!(&sort_by_conversion)
        results = {}
        # Find top X - these are your "high traffic, high conversion". Sort by highest conversions desc
        results["high traffic, high conversion"] = top_segments[0...num_values_to_return].sort(&sort_by_conversion)
        # Find bottom X - these are your "high traffic, low conversion". Sort by lowest conversions
        results["high traffic, low conversion"] = top_segments[-num_values_to_return..-1].sort(&sort_by_conversion).reverse
        # Take the top of the bottom segments - these are your "low traffic, high conversion". Sort by highest conversions desc
        results["low traffic, high conversion"] = bottom_segments[0...num_values_to_return].sort(&sort_by_conversion)
        # Return the results
        return results
      end
    end
  end
end
begin
  Hello::DynamoDB.setup
rescue Exception => e
end
