require 'aws-sdk'
require 'enumerator'

module Hello
  class SegmentData
    attr_accessor :site_id, :segment_key, :segment_value, :views, :conversions
    def initialize(site_id, segment_key, segment_value, views, conversions)
      @site_id, @views, @conversions = site_id, views, conversions
      @segment_key, @segment_value = segment_key, segment_value
    end
      

    def conversion_rate
      unless @conversion_rate
        @conversion_rate = @views == 0 ? 0.0 : @conversions.to_f/@views
      end
      @conversion_rate
    end

    def segment
      unless @segment
        @segment = "#{@segment_key}:#{@segment_value}"
      end
      @segment
    end
  end

  class BarData
    MAX_SEGMENT_LENGTH = 1024

    attr_accessor :site_id, :bar_id, :segment, :views, :conversions
    def initialize(site_id, bar_id, segment, views, conversions)
      @site_id, @bar_id, @segment, @views, @conversions = site_id, bar_id, segment, views, conversions
    end

    def conversion_rate
      unless @conversion_rate
        @conversion_rate = @views == 0 ? 0.0 : @conversions.to_f/@views
      end
      @conversion_rate
    end


    class << self
      # Returns a two-dimensional hash of SegmentData objects. The first key is the segment group and
      # the second key is the segment value. So if had "Country:USA" the first key would be "Country" and
      # the second key would be "USA". The value of the second key is the SegmentData object which tracks
      # the total number of views and conversions for ALL bars specified by bar_ids within that segment.
      # Arguments:
      # - site_id is the site ID as a string
      # - bar_ids is an array of bar IDs as strings to look at
      def get_segment_data(site_id, bar_ids)
        check_connection
        results = []
        # Build the list of attributes to get
        attributes = ["segment"]
        bar_ids.each do |bar_id|
          attributes << "#{bar_id}_v"
          attributes << "#{bar_id}_c"
        end
        site_id = site_id.to_i
        results = Hash.new{|h,k| h[k] = Hash.new{|h2,k2| h2[k2] = SegmentData.new(site_id, k, k2, 0, 0)}}
        @@tables.each do |table|
          table.items.query(:select=>attributes, :hash_value=>site_id).each do |data|
            data = data.attributes
            segment = data.delete("segment")
            segment_key, segment_value = *segment.split(":", 2)
            result = results[segment_key][segment_value]

            data.each do |key, value|
              if key[-1..-1] == "v"
                result.views += value.to_i
              else
                result.conversions += value.to_i
              end
            end
          end
        end

        return results
      end


      # Returns an array of BarData objects with the views and
      # counts for each. 
      # - site_id is the site ID as a string
      # - bar_ids is an array of bar IDs as strings to look at
      # - segments is an array of strings in the format "country:USA", "bar_{bar_id}_XXX:YYY"
      def get_bar_data(site_id, bar_ids, segments)
        check_connection
        results = []
        # Build the list of attributes to get
        attributes = ["segment"]
        bar_ids.each do |bar_id|
          attributes << "#{bar_id}_v"
          attributes << "#{bar_id}_c"
        end
        # Build the list of item keys to get
        site_id = site_id.to_i
        items = segments.collect{|s| [site_id, s[0...MAX_SEGMENT_LENGTH]]}
        bars = Hash.new{|h,k| h[k] = Hash.new{|h2,k2| h2[k2] = {"v"=>0, "c"=>0}}}
        @@tables.each do |table|
          table.batch_get(attributes, items) do |data|
            segment = data.delete("segment")
            data.each do |key, value|
              parts = key.split("_", 2)
              bars[segment][parts[0]][parts[1]] += value.to_i
            end
          end
        end
        bars.each do |segment, bar_data|
          bar_data.each do |bar_id, value|
            results << BarData.new(site_id, bar_id, segment, value["v"], value["c"])
          end
        end
        return results
      end

      def get_over_time_data(site_id, start_date, end_date)
        query_over_time_data(site_id, start_date..end_date)
      end

      def get_all_time_data(site_id)
        query_over_time_data(site_id, 0)
      end

      # Records a view
      # - site_id is the site ID as a string
      # - bar_id is a string
      # - segments is an array of strings in the format "country:USA", "bar_{bar_id}_XXX:YYY"
      def record_view(site_id, bar_id, segments, table=nil)
        record_data(site_id, bar_id, segments, 1, 0, table)
      end

      # Records a conversion
      # - site_id is the site ID as a string
      # - bar_id is a string
      # - segments is an array of strings in the format "country:USA", "bar_{bar_id}_XXX:YYY"
      def record_conversion(site_id, bar_id, segments, table=nil)
        record_data(site_id, bar_id, segments, 0, 1, table)
      end

      # Truncates the data. Usable only in test mode.
      def truncate
        raise "This method only allowed in test mode" unless Rails.env == "test"
        # Iterate through all the items
        (@@tables+[@@over_time_table]).each do |table|
          keys = []
          table.items.each do |item|
            keys << [item.hash_value, item.range_value]
          end
          # Delete them 25 at a time
          keys.each_slice(25) do |key_group|
            table.batch_delete(key_group)
          end
        end
      end

      def tables
        @@tables
      end

      def check_connection
        if @@connected_at
          now = Time.current.utc
          if now - @@connected_at > 60*60 # Been an hour since we connected
            connect!(now)
          end
        else
          connect!
        end
      end

      def set_date(now=nil)
        now = Time.current.utc unless now
        @@date_as_num = now.strftime("%Y%m%d").to_i
      end

      def get_table_name(key)
        return if Rails.env.development?
        table_name = Hellobar::Settings[:dynamo_tables][key.to_sym]
        raise "No table named #{key} in tables #{Hellobar::Settings[:dynamo_tables].keys.inspect}" unless table_name
        {
          "cur_month" => @@cur_month,
          "cur_year" => @@cur_year,
          "prev_month" => @@prev_month,
          "prev_year" => @@prev_year
        }.each do |key, value|
          table_name.gsub!("{#{key}}", value.to_s)
        end
        table_name
      end

      def connect!(now=nil)
        return if Rails.env.development?
        @@dynamo_db = AWS::DynamoDB.new(
          :access_key_id => Hellobar::Settings[:amazon_access_key_id],
          :secret_access_key => Hellobar::Settings[:amazon_secret_access_key]
        )

        now = Time.current.utc unless now
        @@cur_year, @@cur_month = now.year, now.month
        @@prev_year, @@prev_month = @@cur_year, @@cur_month-1
        if @@prev_month == 0
          @@prev_month = 12
          @@prev_year -= 1
        end
        set_date(now)
        @@table = @@dynamo_db.tables[get_table_name("bar_current")]
        @@table.hash_key = {:site_id => :number}
        @@table.range_key = {:segment => :string}
        @@prev_table = @@dynamo_db.tables[get_table_name("bar_prev")]
        @@prev_table.hash_key = {:site_id => :number}
        @@prev_table.range_key = {:segment => :string}
        @@over_time_table = @@dynamo_db.tables[get_table_name("bar_over_time")]
        @@over_time_table.hash_key = {:site_id => :number}
        @@over_time_table.range_key = {:date => :number}

        @@tables = [@@table, @@prev_table]
        @@connected_at = now

      end

      def record_data(site_id, bar_id, segments, views=0, conversions=0, table=nil)
        attributes = {
          :"#{bar_id}_v" => views,
          :"#{bar_id}_c" => conversions
        }
        site_id = site_id.to_i
        table = @@table unless table
        segments.each do |segment|
          segment = segment[0...MAX_SEGMENT_LENGTH] if segment.length > MAX_SEGMENT_LENGTH
          table.items[site_id, segment].attributes.add(attributes)
        end
        # Record for all time
        @@over_time_table.items[site_id, 0].attributes.add(attributes)
        # Record for the date too
        @@over_time_table.items[site_id, @@date_as_num].attributes.add(attributes)
      end

      protected
      def query_over_time_data(site_id, range_value)
        check_connection
        results = []
        @@over_time_table.items.query(
          :hash_value=>site_id,
          :range_value=>range_value
        ).each do |item|
          data = item.attributes.to_hash
          site_id = data.delete("site_id").to_i
          date = data.delete("date").to_i
          bar_data = Hash.new{|h,k| h[k] = {"v"=>0, "c"=>0}}
          data.each do |key, value|
            bar_id, type = key.split("_")
            bar_data[bar_id][type] += value.to_i
          end
          bar_data.each do |bar_id, values|
            results << BarData.new(site_id, bar_id, date, values["v"], values["c"])
          end
        end
        return results
      end

    end
  end
end
