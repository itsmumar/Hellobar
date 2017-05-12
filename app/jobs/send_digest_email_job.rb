class SendDigestEmailJob < ApplicationJob
  def perform(site)
    Hello::EmailDigest.send(site)
  end
end
