namespace :backend do
  desc 'Automatically adjusts DynamoDB tables as needed'
  task :adjust_dynamo_db_capacity do
    require File.join(Rails.root, "config", "initializers", "settings.rb")
    cloudwatch = AWS::CloudWatch::Client.new(
      access_key_id: Hellobar::Settings[:aws_access_key_id],
      secret_access_key: Hellobar::Settings[:aws_secret_access_key]
    )
    dynamo_db = AWS::DynamoDB::Client.new(
      access_key_id: Hellobar::Settings[:aws_access_key_id],
      secret_access_key: Hellobar::Settings[:aws_secret_access_key]
    )
    NUM_DAYS_TO_ANALYZE = 5
    TIME_PERIOD = 60
    MIN_UNITS = 1
    MIN_DIFF = 3
    BUFFER = 1.25
    THROTTLED_CHECK_HOURS = 4
    THROTTLED_TIME_PERIOD = 5*60
    THROTTLE_DIFF = 1.5 # Increase by X% over current capacity

    tables = Hash.new{|h,k| h[k] = Hash.new{|h2,k2| h2[k2] = 0}}
    table_names = dynamo_db.list_tables["TableNames"]

    def fn(num)
      num = num.to_i
      return num if num == 0
      num > 0 ? "+#{num}" : num
    end

    def fm(num)
      num = num.to_i
      return "$0" if num == 0
      num > 0 ? "+$#{num}" : "-$#{num.abs}"
    end
    email_message = []
    email_message << "Gathering data for #{table_names.length} tables..."
    grand_total_diff = 0
    table_names.each do |table_name|
      output = []
      output <<  "\t#{table_name}..."
      results = dynamo_db.describe_table({table_name: table_name})
      tables[table_name][:provisioned_read] = results["Table"]["ProvisionedThroughput"]["ReadCapacityUnits"]
      tables[table_name][:provisioned_write] = results["Table"]["ProvisionedThroughput"]["WriteCapacityUnits"]

      {
        :consumed_write => "ConsumedWriteCapacityUnits",
        :consumed_read => "ConsumedReadCapacityUnits",
      }.each do |key, metric_name|
        NUM_DAYS_TO_ANALYZE.times do |i|
          results = cloudwatch.get_metric_statistics(
            namespace: "AWS/DynamoDB",
            metric_name: metric_name,
            dimensions: [
              {:name=>"TableName", :value=>table_name},
            ],
            start_time: (Time.now-(i+1)*24*60*60).iso8601,
            end_time: (Time.now-i*24*60*60).iso8601,
            period: TIME_PERIOD,
            statistics: ["Sum"],
            unit: "Count"
          )
          tables[table_name][key] = [tables[table_name][key], results[:datapoints].collect{|d| d[:sum]/TIME_PERIOD}.max || 0].max.to_i
        end
      end

      {
        :throttled_write => "WriteThrottleEvents",
        :throttled_read => "ReadThrottleEvents"
      }.each do |key, metric_name|
        results = cloudwatch.get_metric_statistics(
          namespace: "AWS/DynamoDB",
          metric_name: metric_name,
          dimensions: [
            {:name=>"TableName", :value=>table_name},
          ],
          start_time: (Time.now-THROTTLED_CHECK_HOURS*60*60).iso8601,
          end_time: (Time.now).iso8601,
          period: THROTTLED_TIME_PERIOD,
          statistics: ["Sum"],
          unit: "Count"
        )
        tables[table_name][key] = [tables[table_name][key], results[:datapoints].collect{|d| d[:sum]/THROTTLED_TIME_PERIOD}.max || 0].max.to_i
      end
      table = tables[table_name]
      consumed_write = table[:consumed_write]
      consumed_read = table[:consumed_read]

      write_diff = [(consumed_write*BUFFER).round.to_i, MIN_UNITS].max-table[:provisioned_write]
      read_diff = [(consumed_read*BUFFER).round.to_i, MIN_UNITS].max-table[:provisioned_read]
      write_diff = 0 if write_diff.abs < MIN_DIFF
      read_diff = 0 if read_diff.abs < MIN_DIFF
      if table[:throttled_write] and table[:throttled_write] > 50
        output << "\t\tWARN: Writes throttled (#{table[:throttled_write]})"
        write_diff = (table[:provisioned_write]*THROTTLE_DIFF) - table[:provisioned_write]
      end
      if table[:throttled_read] and table[:throttled_read] > 50
        output << "\t\tWARN: Reads throttled (#{table[:Reads]})"
        read_diff = (table[:provisioned_read]*THROTTLE_DIFF) - table[:provisioned_read]
      end

      new_read = table[:provisioned_read]+read_diff
      new_write = table[:provisioned_write]+write_diff

      write_cost_diff = (write_diff/10)*0.0065*24*30.4
      read_cost_diff = (read_diff/50)*0.0065*24*30.4
      total_diff = write_cost_diff+read_cost_diff
      grand_total_diff += total_diff

      output << "\t\twrite: #{table[:provisioned_write]} (#{consumed_write}) => #{new_write} = #{fm write_cost_diff}"
      output <<  "\t\tread: #{table[:provisioned_read]} (#{consumed_read}) => #{new_read} = #{fm read_cost_diff}"
      output << "\t\ttotal: #{fm total_diff}"

      if read_diff != 0 or write_diff != 0
        if ENV['noop']
          output << "\t\tnot adjusting due to no-op..."
        else
          output << "\t\tupdating capacity..."
          dynamo_db.update_table(:table_name=>table_name, :provisioned_throughput => {:read_capacity_units=>new_read, :write_capacity_units=>new_write})
        end
      end
      email_message += output if total_diff.abs > 50
    end
    email_message << "Total: #{fm grand_total_diff}"
    puts email_message.join("\n")
    unless ENV['noop']
      emails = %w{imtall@gmail.com}
      Pony.mail({
        to: emails.join(", "),
        subject: "#{Time.now.strftime("%Y-%m-%d")} DynamoDB: #{fm grand_total_diff}",
        body: email_message.join("\n")
      })
    end
  end
end
