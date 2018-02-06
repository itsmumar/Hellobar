namespace :billing do
  desc 'Runs the recurring billing'
  task run: :environment do
    lock_file_path = Rails.root.join('tmp', 'billing.lock')
    lock_file = File.open(lock_file_path, File::RDWR | File::CREAT, 0644)
    result = lock_file.flock(File::LOCK_EX | File::LOCK_NB)
    raise 'Could not get lock, process already running likely..' if result == false
    # Write this Process ID
    lock_file.write(Process.pid.to_s)
    lock_file.fdatasync
    # Check the pid to make sure we have the lock
    sleep 3
    lock_file_pid = File.read(lock_file_path).to_i
    raise "Expected #{ Process.pid } but was #{ lock_file_pid.inspect }, so exiting" unless lock_file_pid == Process.pid
    puts 'PID matched'

    PayRecurringBills.new.call
  end
end
