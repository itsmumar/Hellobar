class DigestMailer < ActionMailer::Base
  include Roadie::Rails::Mailer
  add_template_helper(EmailDigestHelper)
  default from: "from@example.com"

  def weekly_digest(site)
    @site = site
    @totals = Hello::DataAPI.lifetime_totals_by_type(@site, @site.site_elements, @site.capabilities.num_days_improve_data)
    @se_totals = Hello::DataAPI.lifetime_totals(@site, @site.site_elements, @site.capabilities.num_days_improve_data)
    @sorted_elements = site.site_elements.active.sort_by { |se| @se_totals[se.id.to_s].views_between(1.week.ago + 1.day) }.reverse!
    @conversion_percent_improvement = @totals[:total].conversion_change_between(2.week.ago + 1.day, 1.week.ago, 1.week.ago + 1.day, Time.now)

    roadie_mail(
      to: site.owner.email,
      subject: 'Your Weekly Hello Bar Digest'
    )
  end

  def not_installed(site)
    @site = site

    roadie_mail(
      to: site.owner.email,
      subject: 'One final step and your Hello Bar is live!'
    )
  end
end
