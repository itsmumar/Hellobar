class DigestMailer < ActionMailer::Base
  include Roadie::Rails::Mailer
  include EmailDigestHelper
  default from: "from@example.com"

  def weekly_digest(site)
    @site = site
    @totals = Hello::DataAPI.lifetime_totals_by_type(@site, @site.site_elements, @site.capabilities.num_days_improve_data)
    @se_totals = Hello::DataAPI.lifetime_totals(@site, @site.site_elements, @site.capabilities.num_days_improve_data)
    @cur_conversion = conversion_rate(@totals[:total])
    @one_month_conversion = @cur_conversion - conversion_rate(@totals[:total], 1.month.ago.to_date)

    roadie_mail(
      to: site.owner.email,
      subject: 'Your Weekly Hello Bar Digest'
    )
  end
end
