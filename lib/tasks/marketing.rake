namespace :marketing do
  desc 'Export users who have logged in recently to a files'
  task export_recent_logins_with_plan: :environment do
    %w[Free Pro Enterprise].each do |plan|
      days = 30
      start = Time.zone.now - days.days
      filename = "user_logins_#{ days }_days_#{ plan.downcase }_#{ Time.current.strftime('%F--%H-%M-%S') }.csv"
      users = User.joins(:subscriptions)
                  .where("subscriptions.type = 'Subscription::#{ plan }'")
                  .where(current_sign_in_at: start..Time.zone.now)
                  .order(current_sign_in_at: :desc)
                  .pluck(:email, :current_sign_in_at)
                  .uniq

      users = users.collect { |email, sign_in| "#{ email },#{ sign_in.strftime('%F-%T') }" }
      users.unshift 'Email, Signed In at'
      users.push nil

      File.write(filename, users.join("\n"))
    end
  end

  task export_recent_signups_with_script_install_data: :environment do
    days = 30
    start = Time.zone.now - days.days

    filename = "user_signups_#{ days }_days_no_installed_script_#{ Time.current.strftime('%F--%H-%M-%S') }.csv"
    users = User.joins('LEFT OUTER JOIN site_memberships ON site_memberships.user_id = users.id')
                .joins('LEFT OUTER JOIN sites ON sites.id = site_memberships.site_id AND sites.script_installed_at IS NOT NULL')
                .where('sites.id IS NULL')
                .where(created_at: start..Time.zone.now)
                .order(created_at: :desc)
                .pluck(:email, :created_at)
                .uniq

    users = users.collect { |email, created_at| "#{ email },#{ created_at.strftime('%F-%T') }" }
    users.unshift 'Email, Signed Up at'
    users.push nil
    File.write(filename, users.join("\n"))

    filename = "user_signups_#{ days }_days_1_or_more_installed_scripts_#{ Time.current.strftime('%F--%H-%M-%S') }.csv"
    users = User.joins(:sites)
                .where('sites.script_installed_at IS NOT NULL')
                .where(created_at: start..Time.zone.now)
                .order(created_at: :desc)
                .pluck(:email, :created_at)
                .uniq

    users = users.collect { |email, created_at| "#{ email },#{ created_at.strftime('%F-%T') }" }
    users.unshift 'Email, Signed Up at'
    users.push nil
    File.write(filename, users.join("\n"))
  end
end
