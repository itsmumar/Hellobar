namespace :internal_metrics do
  desc 'Emails a weekly metrics update'
  task :email_weekly => :environment do |t, args|
    last_week=Date.commercial(Date.today.year, Date.today.cweek, 2)
    two_weeks_ago=last_week - 1.week
    sites = Site.where('created_at >= ? and created_at <= ?', two_weeks_ago, last_week).all
    installed_sites = sites.reject{|s| !s.has_script_installed?}
    pro_sites = sites.reject{|s| s.is_free?}
    revenue =Bill.where('created_at >= ? and created_at <= ? and status=1 and amount > 0', two_weeks_ago, last_week)
    sum = revenue.sum(:amount)
    pro = revenue.reject{|b| b.subscription.type !~ /Pro/}
    enterprise = revenue.reject{|b| b.subscription.type !~ /Enterprise/}
    pro_monthly = pro.reject{|b| !b.subscription.monthly?}
    pro_yearly = pro.reject{|b| !b.subscription.yearly?}
    enterprise_monthly = enterprise.reject{|b| !b.subscription.monthly?}
    enterprise_yearly = enterprise.reject{|b| !b.subscription.yearly?}
    include ActionView::Helpers::NumberHelper
    emails = %w{neil@neilpatel.com mike@neilpatel.com}
    Pony.mail({
      to: emails.join(", "),
      subject: "#{last_week} | #{number_with_delimiter(sites.length)} new sites, #{number_to_percentage((installed_sites.length.to_f/sites.length)*100, precision: 1)} install rate, #{number_to_currency(sum)}",
      body: "Report #{two_weeks_ago} to #{last_week}

Created sites: #{number_with_delimiter(sites.length)}

Installed sites: #{number_with_delimiter(installed_sites.length)} (#{number_to_percentage((installed_sites.length.to_f/sites.length)*100, precision: 1)} conversion)

Revenue: #{number_to_currency(sum)}
- Pro (Monthly): #{number_with_delimiter(pro_monthly.length)} (#{number_to_currency(pro_monthly.inject(0){|s,b| s+=b.amount})})
- Pro (Yearly): #{number_with_delimiter(pro_yearly.length)} (#{number_to_currency(pro_yearly.inject(0){|s,b| s+=b.amount})})
- Enterprise (Monthly): #{number_with_delimiter(enterprise_monthly.length)} (#{number_to_currency(enterprise_monthly.inject(0){|s,b| s+=b.amount})})
- Enterprise (Yearly): #{number_with_delimiter(enterprise_yearly.length)} (#{number_to_currency(enterprise_yearly.inject(0){|s,b| s+=b.amount})})
"})
  end

  desc 'Queues a worker for the internal stats processor'
  task :process => :environment do |t, args|
    QueueWorker.send_sqs_message('hello::tracking::internal_stats_harvester:process_internal_stats')
  end
end
