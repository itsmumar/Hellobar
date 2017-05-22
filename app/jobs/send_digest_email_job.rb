class SendDigestEmailJob < ApplicationJob
  def perform(site)
    SendEmailDigest.new(site).call
  end
end
