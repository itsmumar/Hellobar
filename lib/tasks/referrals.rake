namespace :referrals do
  desc "Send reminder emails for referrals who haven't been used yet"
  task send_followups: :environment do |_t, _args|
    Referral.to_be_followed_up.find_each do |ref|
      Referrals::SendSecondEmail.run(referral: ref)
    end
  end
end
