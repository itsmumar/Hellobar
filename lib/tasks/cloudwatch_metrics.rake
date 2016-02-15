namespace :cloudwatch_metrics do
  desc 'Reports memory and disk space stats to AWS CloudWatch'
  task :send do
    instance_id = `ec2metadata --instance-id`
    instance_id.strip!

    memory_usage = `/bin/cat /proc/meminfo`
    memory_usage = memory_usage.split("\n").map { |x| x.split(":")}

    total_memory = memory_usage.detect { |x| x[0] == "MemTotal"}
    total_memory = total_memory[1].to_i

    free_memory = memory_usage.detect { |x| x[0] == "MemFree"}
    free_memory = free_memory[1].to_i

    used_memory = total_memory - free_memory

    disk_usage = `/bin/df -k -l -P /dev/xvda2`
    disk_usage = disk_usage.split("\n").last.split

    disk_total = disk_usage[1]
    disk_used = disk_usage[2]
    disk_available = disk_usage[3]

    metrics = []
    metrics << {metric_name: "TotalMemory", value: total_memory}
    metrics << {metric_name: "FreeMemory", value: free_memory}
    metrics << {metric_name: "UsedMemory", value: used_memory}
    metrics << {metric_name: "TotalDiskSpace", value: disk_total}
    metrics << {metric_name: "UsedDiskSpace", value: disk_used}
    metrics << {metric_name: "AvailableDiskSpace", value: disk_available}


    # Convert the data into the Cloudwatch format
    metrics.each do |metric|
      metric[:dimension] = {name: "InstanceId", value: instance_id}
      metric[:unit] = "kB"
    end

    # Send the data to Cloudwatch
    require File.join(Rails.root, "config/initializers/settings.rb")
    stage = Hellobar::Settings[:env_name]
    cloudwatch = AWS::CloudWatch::Client.new(
      access_key_id: Hellobar::Settings[:aws_access_key_id],
      secret_access_key: Hellobar::Settings[:aws_secret_access_key]
    )
    cloudwatch.put_metric_data({
      namespace: "HB/#{stage}",
      metric_data: metrics
    })
  end
end
