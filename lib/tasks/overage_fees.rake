namespace :overage_fees do
  desc 'Creates overage bills (executed 1x monthly)'
  task run: :environment do
    Site.where.not(overage_count: 0).each do |site|
      CreateAndPayOverageBill.new(site).call
    end
  end
end
