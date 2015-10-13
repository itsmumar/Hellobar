class DigestMailerPreview < ActionMailer::Preview

  def weekly_digest
    s = Site.last
    DigestMailer.weekly_digest(s, current_user)
  end

  def not_installed
    s = Site.first
    DigestMailer.not_installed(s, current_user)
  end
end
