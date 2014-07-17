require 'aws-sdk'
require 'enumerator'

module Hello
  class EmailData
    class << self
      def record_email(goal_id, timestamp, email, name="_")
        goal_id = goal_id.to_i
        timestamp = timestamp.to_i
        name = "_" if !name or name == ""

        @@table.items[goal_id, timestamp].attributes.set({email=>name})
        # We store the total in an attribute on the range value (timestamp) of zero
        @@table.items[goal_id, 0].attributes.add({:total=>1})
      end
      # Returns x most recent emails. The results are returned reverse chronological -
      # with the newest entry first. The results are an array of rows in the format:
      # [
      #   [timestamp, email, name],
      #   [timestamp, email, name],
      #   ...
      # ]
      # the value of name might be nil.
      def get_most_recent_emails(goal_id, limit)
        get_emails(
          :hash_value => goal_id.to_i,
          :scan_index_forward => false,
          :select => :all,
          :limit => limit
        )
      end

      # Returns all emails since the specified timestamp. The results are returned chronologically -
      # with the oldest entry first. The results are an array of rows in the format:
      # [
      #   [timestamp, email, name],
      #   [timestamp, email, name],
      #   ...
      # ]
      # the value of name might be nil.
      def get_emails_since(goal_id, start_timestamp)
        get_emails(
          :hash_value => goal_id.to_i,
          :range_gte => start_timestamp,
          :select => :all
        )
      end
      
      def get_all_emails(goal_id)
        if Rails.env.development?
          get_factory_emails
        else
          get_emails(
            :hash_value => goal_id.to_i,
            :select => :all
          )
        end
      end

      def get_factory_emails
        [ { created_at: Time.now-1.day, email: 'test1@hellobar.com', name: 'Hellobar Test'},
          { created_at: Time.now-2.days, email: 'test2@hellobar.com', name: 'Hellobar Test2'},
          { created_at: Time.now-2.days, email: 'test3@hellobar.com', name: 'Hellobar Test3'} ]
      end

      def num_emails(goal_id)
        return get_factory_emails.size if Rails.env.development?
        # We store the total in an attribute on the range value (timestamp) of zero
        data = nil
        @@table.items.query(:hash_value=>goal_id.to_i, :select => ["total"], :range_value=>0).each do |result|
          data = result
        end
        return 0 unless data
        return data.attributes["total"].to_i
      end

      # Truncates the data. Usable only in test mode.
      def truncate
        raise "This method only allowed in test mode" unless Rails.env == "test"
        # Iterate through all the items
        keys = []
        table.items.each do |item|
          keys << [item.hash_value, item.range_value]
        end
        # Delete them 25 at a time
        keys.each_slice(25) do |key_group|
          table.batch_delete(key_group)
        end
      end

      def connect!
        return if Rails.env.development?
        @@dynamo_db = AWS::DynamoDB.new(
          :access_key_id => Hellobar::Settings[:aws_access_key_id],
          :secret_access_key => Hellobar::Settings[:aws_secret_access_key]
        )
        table_name = Hellobar::Settings[:dynamo_tables][:email]
        @@table = @@dynamo_db.tables[table_name]
        @@table.load_schema
      end

      protected

      def table
        @@table
      end

      def get_emails(options)
        return get_factory_emails if Rails.env.development?
        results = []
        emails_by_index = {}
        @@table.items.query(options).each do |result|
          attributes = result.attributes.to_hash
          timestamp = attributes.delete("timestamp").to_i
          next if timestamp == 0
          attributes.delete("goal_id")
          attributes.each do |email, name|
            if name == "_"
              name = nil
            end
            index = results.length
            existing_index = emails_by_index[email]
            if existing_index
              # update the name if added
              results[existing_index][:name] = name if name
            else
              emails_by_index[email] = index
              # insert
              results << {:created_at=>timestamp, :email=>email, :name=>name}
            end
          end
        end
        return results
      end
    end
  end
end
