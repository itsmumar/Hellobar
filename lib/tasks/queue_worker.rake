namespace :queue_worker do
  desc 'Starts all the queue workers'
  task :start do
    require File.join(Rails.root, "config", "initializers", "settings.rb")

    {
      Hellobar::Settings[:main_queue] => 2,
      Hellobar::Settings[:low_priority_queue] => 3
    }.each do |queue, num_workers|
      puts "Strating #{num_workers} workers for #{queue.inspect}"
      cmd = "cd #{Rails.root} && RAILS_ENV=#{Rails.env} bundle exec bin/queue_worker -- -q #{queue} -n #{num_workers}"
      puts cmd
      `#{cmd}`
    end
  end


  desc 'Stops all the queue workers'
  task :stop do
    processes = `ps aux`.split("\n").reject{|l| l !~ /queue_worker\s*\[.*?\]/}
    puts "Stopping #{processes.length} queue workers..."
    processes.each do |process|
      pid = process.split(/\s+/)[1].to_i
      cmd = "kill #{pid}"
      puts cmd
      `#{cmd}`
    end
  end

  desc 'Restarts all the queue workers'
  task :restart do
    Rake::Task["queue_worker:stop"].invoke
    Rake::Task["queue_worker:start"].invoke
  end
end
