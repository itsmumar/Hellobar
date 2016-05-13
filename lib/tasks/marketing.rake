namespace :marketing do
  desc "Export users who have logged in recently to a files"
  task :export_recent_logins => :environment do
    [30, 60].each do |days|
      filename = "user_logins_#{days}_days_#{Time.now.strftime("%F--%H-%M-%S")}.csv"
      start = Time.zone.now - days.days
      users = User.where(current_sign_in_at: start..Time.zone.now).
                   order(current_sign_in_at: :desc).
                   pluck(:email, :current_sign_in_at)

      users = users.collect{|email, sign_in| "#{email},#{sign_in.strftime("%F-%T")}"}
      users.unshift "Email, Signed In at"
      users.push nil

      File.write(filename, users.join("\n"))
    end
  end
end
