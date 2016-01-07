namespace :referrals do
  desc "Send reminder emails for referrals who haven't been used yet"
  task :send_reminders => :environment do |t, args|
    Referral.about_to_expire.find_each do |ref|
      Referrals::SendSecondEmail.run(referral: ref)
    end
  end
end