class MailerGateway
  def self.gateway
    GrandCentralApi.new("http://central.crazyegg.com", Hellobar::Settings[:grand_central_api_key], Hellobar::Settings[:grand_central_api_secret])
  end

  def self.send_email(type, recipient = "support@hellobar.com", params = {})
    gateway.send_mail(type, {recipient => params})
  end
end
