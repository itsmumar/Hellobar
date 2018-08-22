class WarningMailer < ApplicationMailer
  def warning_email(site, number_of_views, limit, warning_level)
    @site = site
    @number_of_views = number_of_views
    @limit = limit
    @warning_level = warning_level
    users = site.owners_and_admins

    users.each do |user|
      @user = user
      mail(to: user.email, subject: "You're approaching your Hello Bar monthly view limit!")
    end
  end
end
