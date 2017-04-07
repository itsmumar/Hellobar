namespace :queue_worker do
  WORKER_PATTERN = /queue_worker\s*\[(.*?)\]/

  desc 'Starts all the queue workers'
  task :start do
    require Rails.root.join('config', 'initializers', 'settings.rb')
    root = Rails.root

    {
      Hellobar::Settings[:main_queue] => [2],
      Hellobar::Settings[:low_priority_queue] => [2, '--skip-old']
    }.each do |queue, options|
      num_workers = options[0]
      additional_options = options[1] || ''
      puts "Starting #{ num_workers } workers for #{ queue.inspect }"
      cmd = "cd #{ root } && RAILS_ENV=#{ Rails.env } bundle exec bin/queue_worker -- -q #{ queue } -n #{ num_workers } #{ additional_options }"
      puts cmd
      `#{cmd}`
    end
  end

  desc 'Stops all the queue workers'
  task :stop do
    processes = `ps aux`.split("\n").reject { |l| l !~ WORKER_PATTERN }
    puts "Stopping #{ processes.length } queue workers..."
    processes.each do |process|
      pid = process.split(/\s+/)[1].to_i
      cmd = "kill #{ pid }"
      puts cmd
      `#{cmd}`
    end
  end

  desc 'Restarts all the queue workers'
  task :restart do
    Rake::Task['queue_worker:stop'].invoke
    Rake::Task['queue_worker:start'].invoke
  end

  desc 'Restarts only workers that are not currently running'
  task :resurrect do
    root = Rails.root
    require Rails.root.join('config', 'initializers', 'settings.rb')

    processes = `ps aux`.split("\n").reject { |l| l !~ WORKER_PATTERN }
    {
      Hellobar::Settings[:main_queue] => [2],
      Hellobar::Settings[:low_priority_queue] => [2, '--skip-old']
    }.each do |queue, options|
      num_workers = options[0]
      additional_options = options[1] || ''
      puts "Expecting #{ num_workers } workers for #{ queue.inspect }"
      num_workers_found = 0
      processes.each do |process|
        if process =~ WORKER_PATTERN
          num_workers_found += 1 if Regexp.last_match(1) == queue.to_s
        end
      end
      num_workers_needed = num_workers - num_workers_found
      puts "Found #{ num_workers_found }. Starting #{ num_workers_needed }..."
      next unless num_workers_needed > 0
      cmd = "cd #{ root } && RAILS_ENV=#{ Rails.env } bundle exec bin/queue_worker -- -q #{ queue } -n #{ num_workers_needed } #{ additional_options }"
      puts cmd
      `#{cmd}`
    end
  end

  desc 'Reports queue_worker stats to AWS CloudWatch'
  task :metrics do
    # Note: the cutoff time should match how frequently
    # the metrics are updated
    cut_off_time = Time.now - 5.minutes
    # Set zero values in case the logs don't have any values
    stats = {
      'Errors' => 0,
      'NumJobsReceived' => 0,
      'NumJobsProcessed' => 0
    }
    # Scan through the log backwards using Efil until
    # you find a line that doesn't meet the cut_off_time
    log_line_pattern = /\[(.*?)\] (\d\d\d\d\-\d\d\-\d\d \d\d:\d\d:\d\d UTC) .*? => (.*)/
    num_lines = 0
    require 'queue_worker/queue_worker'

    Elif.open(QueueWorker::LOG_FILE) do |file|
      loop do
        # Stop processing once we reach the end of the file
        line = file.gets
        num_lines += 1
        break unless line
        # Parse the line
        next unless line =~ log_line_pattern
        type = Regexp.last_match(1)
        date = Regexp.last_match(2)
        message = Regexp.last_match(3)
        date = Time.parse(date)
        # Stop processing once we reach the cut off date
        break unless date > cut_off_time
        if type == 'ERRO'
          stats['Errors'] += 1
        elsif message =~ /Received/
          stats['NumJobsReceived'] += 1
        elsif message =~ /Processed/
          stats['NumJobsProcessed'] += 1
        end
      end
    end
    puts "Scanned #{ num_lines } lines of data"

    # Convert the data into the Cloudwatch format
    metrics = []
    host = `hostname`.chomp # Get the hostname so we can filter by host
    dimensions = [
      [{ name: 'Host', value: host }],
      [{ name: 'System', value: 'All' }]
    ]
    stats.each do |name, value|
      dimensions.each do |dimension|
        metrics << {
          metric_name: "QueueWorker#{ name }",
          dimensions: dimension,
          value: value,
          unit: 'Count'
        }
      end
    end

    # Send the data to Cloudwatch
    require Rails.root.join('config', 'initializers', 'settings.rb')
    stage = Hellobar::Settings[:env_name]
    data = {
      namespace: "HB/#{ stage }",
      metric_data: metrics
    }
    pp data
    cloudwatch = AWS::CloudWatch::Client.new(
      access_key_id: Hellobar::Settings[:aws_access_key_id],
      secret_access_key: Hellobar::Settings[:aws_secret_access_key]
    )
    response = cloudwatch.put_metric_data(data)
    pp response
  end
end
