class DigestMailerPreview < ActionMailer::Preview

  def weekly_digest
    s = Site.first
    DigestMailer.weekly_digest(s)
  end

  def not_installed
    s = Site.first
    DigestMailer.not_installed(s)
  end
end
