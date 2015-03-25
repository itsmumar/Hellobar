class DigestMailer < ActionMailer::Base
  default from: "from@example.com"

  def weekly_digest(site)
    mail(
      to: site.owner.email,
      subject: 'Your Weekly Hello Bar Digest'
    )
  end
end
