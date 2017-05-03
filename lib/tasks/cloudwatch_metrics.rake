namespace :cloudwatch_metrics do
  desc 'Reports memory and disk space stats to AWS CloudWatch'
  task :send do
    instance_id = `ec2metadata --instance-id`
    instance_id.strip!

    memory_usage = `/bin/cat /proc/meminfo`
    memory_usage = memory_usage.split("\n").map { |x| x.split(':') }

    total_memory = memory_usage.detect { |x| x[0] == 'MemTotal' }
    total_memory = total_memory[1].to_i

    free_memory = memory_usage.detect { |x| x[0] == 'MemFree' }
    free_memory = free_memory[1].to_i

    used_memory = total_memory - free_memory

    disk_usage = `/bin/df -k -l -P /dev/xvda2`
    disk_usage = disk_usage.split("\n").last.split

    disk_total = disk_usage[1]
    disk_used = disk_usage[2]
    disk_available = disk_usage[3]

    metrics = []
    metrics << { metric_name: 'TotalMemory', value: total_memory }
    metrics << { metric_name: 'FreeMemory', value: free_memory }
    metrics << { metric_name: 'UsedMemory', value: used_memory }
    metrics << { metric_name: 'TotalDiskSpace', value: disk_total }
    metrics << { metric_name: 'UsedDiskSpace', value: disk_used }
    metrics << { metric_name: 'AvailableDiskSpace', value: disk_available }

    # Convert the data into the Cloudwatch format
    metrics.each do |metric|
      metric[:dimensions] = [{ name: 'InstanceId', value: instance_id }]
      metric[:unit] = 'Kilobytes'
    end

    # Send the data to Cloudwatch
    require Rails.root.join('config', 'initializers', 'settings.rb')

    cloudwatch = AWS::CloudWatch::Client.new(
      access_key_id: Hellobar::Settings[:aws_access_key_id],
      secret_access_key: Hellobar::Settings[:aws_secret_access_key],
      logger: nil
    )

    cloudwatch.put_metric_data(namespace: "HB/#{ Rails.env }", metric_data: metrics)
  end

  desc 'Creates alarms for disk space and memory'
  task :create_alarms do
    require Rails.root.join('config', 'initializers', 'settings.rb')

    instance_id = `ec2metadata --instance-id`
    instance_id.strip!
    namespace = "HB/#{ Rails.env }"

    cloudwatch = AWS::CloudWatch::Client.new(
      access_key_id: Hellobar::Settings[:aws_access_key_id],
      secret_access_key: Hellobar::Settings[:aws_secret_access_key],
      logger: nil
    )

    ########################################
    #### DISK SPACE Alarm Creation
    ########################################
    cloudwatch.put_metric_alarm(
      alarm_name: "Disk Space Alarm - #{ instance_id }", # required
      alarm_description: 'Alerts when the instance is low on disk space',
      actions_enabled: true,
      alarm_actions: ['arn:aws:sns:us-east-1:199811731772:alarms'],
      metric_name: 'AvailableDiskSpace', # required
      namespace: namespace, # required
      statistic: 'Average', # required, accepts SampleCount, Average, Sum, Minimum, Maximum
      dimensions: [
        {
          name: 'InstanceId', # required
          value: instance_id, # required
        }
      ],
      period: 5 * 60, # required - 5 minutes
      unit: 'Kilobytes', # accepts Seconds, Microseconds, Milliseconds, Bytes, Kilobytes, Megabytes, Gigabytes, Terabytes, Bits, Kilobits, Megabits, Gigabits, Terabits, Percent, Count, Bytes/Second, Kilobytes/Second, Megabytes/Second, Gigabytes/Second, Terabytes/Second, Bits/Second, Kilobits/Second, Megabits/Second, Gigabits/Second, Terabits/Second, Count/Second, None
      evaluation_periods: 2, # required
      threshold: 5_000_000.0, # required - 5GB
      comparison_operator: 'LessThanOrEqualToThreshold', # required, accepts GreaterThanOrEqualToThreshold, GreaterThanThreshold, LessThanThreshold, LessThanOrEqualToThreshold
    )

    ########################################
    #### MEMORY Alarm Creation
    ########################################
    cloudwatch.put_metric_alarm(
      alarm_name: "Memory Low Alarm - #{ instance_id }", # required
      alarm_description: 'Alerts when the instance is low on memory',
      actions_enabled: true,
      alarm_actions: ['arn:aws:sns:us-east-1:199811731772:alarms'],
      metric_name: 'FreeMemory', # required
      namespace: namespace, # required
      statistic: 'Average', # required, accepts SampleCount, Average, Sum, Minimum, Maximum
      dimensions: [
        {
          name: 'InstanceId', # required
          value: instance_id, # required
        }
      ],
      period: 5 * 60, # required - 5 minutes
      unit: 'Kilobytes', # accepts Seconds, Microseconds, Milliseconds, Bytes, Kilobytes, Megabytes, Gigabytes, Terabytes, Bits, Kilobits, Megabits, Gigabits, Terabits, Percent, Count, Bytes/Second, Kilobytes/Second, Megabytes/Second, Gigabytes/Second, Terabytes/Second, Bits/Second, Kilobits/Second, Megabits/Second, Gigabits/Second, Terabits/Second, Count/Second, None
      evaluation_periods: 2, # required
      threshold: 500_000.0, # required - 500MB
      comparison_operator: 'LessThanOrEqualToThreshold', # required, accepts GreaterThanOrEqualToThreshold, GreaterThanThreshold, LessThanThreshold, LessThanOrEqualToThreshold
    )
  end
end
