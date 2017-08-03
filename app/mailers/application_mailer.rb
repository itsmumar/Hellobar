class ApplicationMailer < ActionMailer::Base
  default from: 'Hello Bar <contact@hellobar.com>'
  layout 'mailer'
end
