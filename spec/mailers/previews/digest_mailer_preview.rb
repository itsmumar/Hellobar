class DigestMailerPreview < ActionMailer::Preview
  def weekly_digest
    s = Site.last
    DigestMailer.weekly_digest(s, User.last)
  end

  def not_installed
    s = Site.first
    DigestMailer.not_installed(s, User.last)
  end
end
