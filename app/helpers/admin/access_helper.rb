module Admin::AccessHelper
  require 'rqrcode'

  def qr_code_from(otp)
    @qr ||= RQRCode::QRCode.new(otp) if otp.present?
  end
end
