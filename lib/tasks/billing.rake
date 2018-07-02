namespace :billing do
  desc 'Runs the recurring billing (executed daily)'
  task run: :environment do
    PayRecurringBills.new.call
  end
end
