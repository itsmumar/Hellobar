class MailerGateway
  def self.gateway
    GrandCentralApi.new('http://central.hellobar.com', Settings.grand_central_api_key, Settings.grand_central_api_secret)
  end

  def self.send_email(type, recipient = 'support@hellobar.com', params = {})
    return true unless Settings.deliver_emails
    gateway.send_mail(type, recipient => params)
  end
end
