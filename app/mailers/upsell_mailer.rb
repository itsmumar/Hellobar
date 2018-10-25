class UpsellMailer < ApplicationMailer
  def upsell_email(site, number_of_views, limit)
    @site = site
    @number_of_views = number_of_views
    @limit = limit
    users = site.owners_and_admins

    users.each do |user|
      @user = user
      mail(to: user.email, subject: 'You could be saving money by upgrading your Hello Bar Subscription')
    end
  end

  def elite_upsell_email(site, number_of_views, limit)
    @site = site
    @number_of_views = number_of_views
    @limit = limit
    users = site.owners_and_admins
    hb_team = ['seth@hellobar.com', 'karen@hellobar.com', 'lindsey@hellobar.com', 'keith@neilpatel.com', 'mike@hellobar.com']

    users.each do |user|
      @user = user
      mail(to: user.email, subject: 'You could be saving money by upgrading your Hello Bar Subscription')
    end

    hb_team.each do |user|
      @user = user
      mail(to: user, subject: 'Heads up! An Elite customer is paying a lot in overage fees')
    end
  end

  def auto_upgrade_email(site, number_of_views, limit)
    @site = site
    @number_of_views = number_of_views
    @limit = limit
    users = site.owners_and_admins

    users.each do |user|
      @user = user
      mail(to: user.email, subject: 'We’re Saving You Money: Changes to Your Hello Bar Account')
    end
  end
end
