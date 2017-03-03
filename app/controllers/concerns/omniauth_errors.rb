module OmniauthErrors
  extend ActiveSupport::Concern

  def omniauth_error?
    request.env['omniauth.error'] || request.env['omniauth.error.type']
  end

  def omniauth_error_message
    message = request.env['omniauth.error'].try(:message) ||  request.env['omniauth.error.type']
    return nil if message.nil?
    message.to_s.split('|').last.try(:strip) || ''
  end
end
