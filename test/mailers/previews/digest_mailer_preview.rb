class DigestMailerPreview < ActionMailer::Preview

  def weekly_digest
    s = Site.first
    DigestMailer.weekly_digest(s)
  end

end
