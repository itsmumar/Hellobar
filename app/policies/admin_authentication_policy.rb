class AdminAuthenticationPolicy
  attr_accessor :otp

  def initialize(resource)
    @admin = resource
    @otp = generate_otp
  end

  def otp_valid?(otp)
    totp.verify(otp)
  end

  private

  def totp
    @totp ||= initialize_totp
  end

  def generate_otp
    totp.provisioning_uri(@admin.email)
  end

  def initialize_totp
    ROTP::TOTP.new rotp_secret, issuer: Admin::ISSUER
  end

  def rotp_secret
    Rails.application.secrets[:rotp_secret_key_base]
  end
end
