namespace :overage_fees do
  desc 'Creates overage bills (executed 1x monthly)'
  task run: :environment do
    Site.active.where.not(overage_count: 0).find_in_batches do |group|
      group.each do |site|
        CreateOverageBill.new(site).call
      end
    end
  end
end
