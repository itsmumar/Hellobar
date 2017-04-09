class AdminAuthenticationPolicy
  def initialize(resource)
    @admin = resource
  end

  def otp_valid?(otp)
    totp.verify(otp.delete(' '))
  end

  def generate_otp
    totp.provisioning_uri(@admin.email)
  end

  private

  def totp
    @totp ||= ROTP::TOTP.new(@admin.decrypted_rotp_secret_base, issuer: Admin::ISSUER)
  end
end
