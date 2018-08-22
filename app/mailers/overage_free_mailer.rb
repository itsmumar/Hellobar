class OverageFreeMailer < ApplicationMailer
  def overage_email(site, number_of_views, limit)
    @site = site
    @number_of_views = number_of_views
    @limit = limit
    users = site.owners_and_admins

    users.each do |user|
      @user = user
      mail(to: user.email, subject: "You have exceeded your Hello Bar monthly view limit!")
    end
  end
end
