class WarningMailer < ApplicationMailer
  def warning_email(site, number_of_views, limit, warning_level)
    @site = site
    @number_of_views = number_of_views
    @limit = limit
    @warning_level = warning_level
    users = site.owners_and_admins

    users.each do |user|
      @user = user
      mail(to: user.email, subject: 'You are approaching your Hello Bar monthly view limit!')
    end
  end

  def warning_free_email(site, number_of_views, limit, warning_level)
    @site = site
    @number_of_views = number_of_views
    @limit = limit
    @warning_level = warning_level
    users = site.owners_and_admins

    users.each do |user|
      @user = user
      mail(to: user.email, subject: 'You are approaching your Hello Bar monthly view limit!')
    end
  end

  def black_friday_one(site, number_of_views, limit, warning_level)
    @site = site
    @number_of_views = number_of_views
    @limit = limit
    @warning_level = warning_level
    users = site.owners_and_admins

    users.each do |user|
      @user = user
      mail(to: user.email, subject: 'Hello Bar View Limit Approaching: Don’t Miss Out On Your Slice Of Money Pie This Black Friday!')
    end
  end

  def black_friday_two(site, number_of_views, limit, warning_level)
    @site = site
    @number_of_views = number_of_views
    @limit = limit
    @warning_level = warning_level
    users = site.owners_and_admins

    users.each do |user|
      @user = user
      mail(to: user.email, subject: 'Hello Bar 🚨 Warning: Your Site Is In Danger of Missing Out This Black Friday')
    end
  end

  def black_friday_three(site, number_of_views, limit, warning_level)
    @site = site
    @number_of_views = number_of_views
    @limit = limit
    @warning_level = warning_level
    users = site.owners_and_admins

    users.each do |user|
      @user = user
      mail(to: user.email, subject: 'Hello Bar ⚠️ You’re 500 Views Away From Missing Out On The Busiest Sales')
    end
  end
end
