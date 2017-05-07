namespace :backend do
  desc 'Automatically adjusts DynamoDB tables as needed'
  task :adjust_dynamo_db_capacity, [:type] => :environment do |_t, args|
    cloudwatch = AWS::CloudWatch::Client.new(
      access_key_id: Settings.aws_access_key_id,
      secret_access_key: Settings.aws_secret_access_key,
      logger: nil
    )

    dynamo_db = AWS::DynamoDB::Client.new(
      access_key_id: Settings.aws_access_key_id,
      secret_access_key: Settings.aws_secret_access_key,
      logger: nil
    )

    NUM_DAYS_TO_ANALYZE = 3
    TIME_PERIOD = 60
    MIN_UNITS = 1
    MIN_DIFF = 3
    BUFFER = 1.25 # Buffer from consumed capacity
    # The key difference between recurring and recent is both the number
    # of hours checked and the fact that recurring buffer is based on the
    # consumed capacity, while the recent checks the current capacity
    RECURRING_THROTTLED_CHECK_HOURS = 24
    RECURRING_THROTTLED_TIME_PERIOD = 3 * 60
    RECURRING_THROTTLE_BUFFER = 1.5 # Increase by X% over consumed capacity
    RECENT_THROTTLED_CHECK_HOURS = 1
    RECENT_THROTTLED_TIME_PERIOD = 5 * 60
    RECENT_THROTTLE_BUFFER = 1.15 # Increase by X% over current capacity
    MAX_INCREASE = 1_000
    MIN_WRITE_CAPACITY_CURRENT_MONTH = 5
    MIN_READ_CAPACITY_CURRENT_MONTH = 5

    tables = Hash.new { |h, k| h[k] = Hash.new { |h2, k2| h2[k2] = 0 } }
    table_names = dynamo_db.list_tables['TableNames']

    def fn(num)
      num = num.to_i
      return num if num == 0
      num > 0 ? "+#{ num }" : num
    end

    def fm(num)
      num = num.to_i
      return '$0' if num == 0
      num > 0 ? "+$#{ num }" : "-$#{ num.abs }"
    end
    email_message = []
    email_message << "Checking #{ args[:type] == 'recent_throttled_only' ? 'recent throttled ata only' : 'all data' }"
    email_message << "Gathering data for #{ table_names.length } tables..."
    grand_total_diff = 0
    table_names.each do |table_name|
      output = []
      output << "\t#{ table_name }..."
      results = dynamo_db.describe_table(table_name: table_name)
      tables[table_name][:provisioned_read] = results['Table']['ProvisionedThroughput']['ReadCapacityUnits']
      tables[table_name][:provisioned_write] = results['Table']['ProvisionedThroughput']['WriteCapacityUnits']

      unless args[:type] == 'recent_throttled_only'
        {
          consumed_write: 'ConsumedWriteCapacityUnits',
          consumed_read: 'ConsumedReadCapacityUnits'
        }.each do |key, metric_name|
          NUM_DAYS_TO_ANALYZE.times do |i|
            results = cloudwatch.get_metric_statistics(
              namespace: 'AWS/DynamoDB',
              metric_name: metric_name,
              dimensions: [
                { name: 'TableName', value: table_name }
              ],
              start_time: (Time.current - (i + 1) * 24 * 60 * 60).iso8601,
              end_time: (Time.current - i * 24 * 60 * 60).iso8601,
              period: TIME_PERIOD,
              statistics: ['Sum'],
              unit: 'Count'
            )
            tables[table_name][key] = [tables[table_name][key], results[:datapoints].collect { |d| d[:sum] / TIME_PERIOD }.max || 0].max.to_i
          end
        end
      end
      throttled_metrics = {
        recent_throttled_write: 'WriteThrottleEvents',
        recent_throttled_read: 'ReadThrottleEvents'
      }
      unless args[:type] == 'recent_throttled_only'

        throttled_metrics[:recurring_throttled_write] = 'WriteThrottleEvents'
        throttled_metrics[:recurring_throttled_read] = 'ReadThrottleEvents'
      end
      throttled_metrics.each do |key, metric_name|
        check_hours = key.to_s =~ /recent/ ? RECENT_THROTTLED_CHECK_HOURS : RECURRING_THROTTLED_CHECK_HOURS
        time_period = key.to_s =~ /recent/ ? RECENT_THROTTLED_TIME_PERIOD : RECURRING_THROTTLED_TIME_PERIOD
        results = cloudwatch.get_metric_statistics(
          namespace: 'AWS/DynamoDB',
          metric_name: metric_name,
          dimensions: [
            { name: 'TableName', value: table_name }
          ],
          start_time: (Time.current - check_hours * 60 * 60).iso8601,
          end_time: Time.current.iso8601,
          period: time_period,
          statistics: ['Sum'],
          unit: 'Count'
        )
        tables[table_name][key] = [tables[table_name][key], results[:datapoints].collect { |d| d[:sum] / time_period }.max || 0].max.to_i
      end
      table = tables[table_name]
      next unless (args[:type] != 'throttled_only') || table[:recent_throttled_write].to_i > 50 || table[:recent_throttled_read].to_i > 50

      write_diff = 0
      read_diff = 0
      unless args[:type] == 'recent_throttled_only'
        consumed_write = table[:consumed_write]
        consumed_read = table[:consumed_read]

        write_buffer = BUFFER
        if table[:recurring_throttled_write].to_i > 50
          output << "\t\tWARN: Writes recurring throttled (#{ table[:recurring_throttled_write] })"
          write_buffer = RECURRING_THROTTLE_BUFFER
        end
        read_buffer = BUFFER
        if table[:recurring_throttled_read].to_i > 50
          output << "\t\tWARN: Reads recurring throttled (#{ table[:recurring_throttled_read] })"
          read_buffer = RECURRING_THROTTLE_BUFFER
        end

        is_current_segment_table = false
        date = Time.current
        # Check today
        is_current_segment_table = true if table_name.to_s == "segments_#{ date.year }_#{ date.month }"
        # Check tomorrow too
        date += 24 * 60 * 60
        is_current_segment_table = true if table_name.to_s == "segments_#{ date.year }_#{ date.month }"

        min_write = is_current_segment_table ? MIN_WRITE_CAPACITY_CURRENT_MONTH : MIN_UNITS
        min_read = is_current_segment_table ? MIN_READ_CAPACITY_CURRENT_MONTH : MIN_UNITS

        write_diff = [(consumed_write * write_buffer).round.to_i, min_write].max - table[:provisioned_write]
        read_diff = [(consumed_read * read_buffer).round.to_i, min_read].max - table[:provisioned_read]
        write_diff = 0 if write_diff.abs < MIN_DIFF
        read_diff = 0 if read_diff.abs < MIN_DIFF
      end
      if table[:recent_throttled_write].to_i > 50
        output << "\t\tWARN: Writes recently throttled (#{ table[:recent_throttled_write] })"
        write_diff = [(table[:provisioned_write] * RECENT_THROTTLE_BUFFER) - table[:provisioned_write], MAX_INCREASE].min
      end
      if table[:recent_throttled_read].to_i > 50
        output << "\t\tWARN: Reads recently throttled (#{ table[:recent_throttled_read] })"
        read_diff = [(table[:provisioned_read] * RECENT_THROTTLE_BUFFER) - table[:provisioned_read], MAX_INCREASE].min
      end

      new_read = table[:provisioned_read] + read_diff
      new_write = table[:provisioned_write] + write_diff

      write_cost_diff = (write_diff / 10) * 0.0065 * 24 * 30.4
      read_cost_diff = (read_diff / 50) * 0.0065 * 24 * 30.4
      total_diff = write_cost_diff + read_cost_diff
      grand_total_diff += total_diff

      output << "\t\twrite: #{ table[:provisioned_write] } (#{ consumed_write }) => #{ new_write } = #{ fm write_cost_diff }"
      output << "\t\tread: #{ table[:provisioned_read] } (#{ consumed_read }) => #{ new_read } = #{ fm read_cost_diff }"
      output << "\t\ttotal: #{ fm total_diff }"

      if (read_diff != 0) || (write_diff != 0)
        if ENV['noop']
          output << "\t\tnot adjusting due to no-op..."
        else
          output << "\t\tupdating capacity..."
          dynamo_db.update_table(table_name: table_name, provisioned_throughput: { read_capacity_units: new_read, write_capacity_units: new_write })
        end
      end
      email_message += output if total_diff.abs > 50
    end
    email_message << "Total: #{ fm grand_total_diff }"
    puts email_message.join("\n")
    unless ENV['noop']
      emails = %w[mailmanager@hellobar.com]
      if grand_total_diff != 0
        Pony.mail(to: emails.join(', '),
                  subject: "#{ Time.current.strftime('%Y-%m-%d') } #{ args[:type].inspect } DynamoDB: #{ fm grand_total_diff }",
                  body: email_message.join("\n\r"))
      end
    end
  end
end
