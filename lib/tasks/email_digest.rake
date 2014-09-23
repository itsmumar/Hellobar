namespace :email_digest do
  task :deliver_installed => :environment do
    Hello::EmailDigest.installed_sites.each do |site|
      next unless user = site.owner

      metrics = Hello::EmailDigest.site_metrics(site)
      email_name = Hello::EmailDigest.email_name(site)
      params = Hello::EmailDigest.installed_params(site, user, metrics, email_name)

      MailerGateway.send_email("Email Digest", user.email, params)
      Hello::EmailDigest.track_send(user, email_name)
    end
  end

  task :deliver_not_installed => :environment do
    Hello::EmailDigest.not_installed_sites.each do |site|
      next unless user = site.owner

      email_name = Hello::EmailDigest.email_name(site)
      params = Hello::EmailDigest.not_installed_params(site, user, email_name)

      MailerGateway.send_email("Email Digest (Not Installed)", user.email, params)
      Hello::EmailDigest.track_send(user, email_name)
    end
  end
end
