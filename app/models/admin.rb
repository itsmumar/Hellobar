class Admin < ActiveRecord::Base
  LOCKDOWN_KEY_EXPIRY = 2.hours
  MAX_ACCESS_TOKENS = 10
  MAX_LOGIN_ATTEMPTS = 10
  MAX_SESSION_TIME = 24.hours
  MAX_TIME_BEFORE_NEEDS_NEW_PASSWORD = 90.days
  MIN_PASSWORD_LENGTH = 8
  SALT = 'thisismyawesomesaltgoducks'.freeze
  ISSUER = 'HelloBar'.freeze

  include Rails.application.routes.url_helpers

  validates :password_hashed, presence: true

  before_validation :set_default_password, on: :create

  after_create :generate_rotp_secret_base!

  scope :locked, -> { where(locked: true) }

  class << self
    def make(email, initial_password)
      Admin.new(email: email, initial_password: initial_password)
    end

    def make!(email, initial_password)
      make(email, initial_password).tap(&:save!)
    end

    def validate_session(token)
      return if token.blank?

      if (admin = Admin.find_by(session_token: token))
        return if Time.current - admin.session_last_active > MAX_SESSION_TIME

        admin.session_heartbeat!
        return if admin.locked?
      end

      admin
    end

    def record_login_attempt(email, ip, user_agent, access_cookie)
      AdminLoginAttempt.create!(
        email: email,
        ip_address: ip,
        user_agent: user_agent,
        access_cookie: access_cookie,
        attempted_at: Time.current
      )
    end

    def validate_lockdown(email, key, timestamp)
      key == lockdown_key(email, timestamp) && (Time.current.to_i - timestamp) < LOCKDOWN_KEY_EXPIRY
    end

    def lockdown_key(email, timestamp)
      Digest::SHA256.hexdigest(['lockdown', email, timestamp, 'lockitnow'].join(''))
    end

    # Locks all admins
    def lockdown!
      Admin.all.find_each(&:lock!)
    end

    def unlock_all!
      Admin.update_all(login_attempts: 0, locked: 0)
    end
  end

  def logout!
    update_attribute(:session_token, '')
  end

  def needs_otp_code?
    authentication_code.blank? || rotp_secret_base.blank?
  end

  def generate_new_otp!
    authentication_policy.generate_otp
  end

  # Validates the access_token, password and otp_code
  # Makes sure not locked
  # Save entered_otp, so next time user won't see the barcode rendered again.
  # Also increases the login_attempts and locks it down if reaches MAX_LOGIN_ATTEMPTS
  # If this is a valid login then we call login!. Returns true if everything
  # is valid, false otherwise
  def validate_login(password, entered_otp)
    update_attribute(:login_attempts, login_attempts + 1)
    update_attribute(:authentication_code, entered_otp)

    lock! if login_attempts > MAX_LOGIN_ATTEMPTS
    return false if locked? ||
                    !valid_authentication_otp?(entered_otp) ||
                    password_hashed != encrypt_password(password)

    login!
    true
  end

  def valid_authentication_otp?(otp)
    authentication_policy.otp_valid?(otp)
  end

  def reset_password!(unencrypted_password)
    timestamp = Time.current
    self.password_last_reset = timestamp
    self.password = unencrypted_password
    save!

    lockdown_url = admin_lockdown_url(email: email, key: Admin.lockdown_key(email, timestamp.to_i), timestamp: timestamp.to_i, host: Settings.host)

    Pony.mail(
      to: email,
      subject: 'Your password has been reset',
      body: "If this is not you, this may be an attack and you should lock down the admin by clicking this link:

        Not me, lock it down -> #{ lockdown_url }

"
    )
  end

  # Reset login_attempts, session_token and session_last_active
  def login!
    return false if locked?

    update_attributes(
      login_attempts: 0,
      session_token: hexdigest([Time.current.to_i, rand(10_000), email, rand(10_000)].map(&:to_s).join(''))
    )
    session_heartbeat!
  end

  def needs_to_set_new_password?
    !password_last_reset || Time.current - password_last_reset > MAX_TIME_BEFORE_NEEDS_NEW_PASSWORD
  end

  def lock!
    update_attributes(locked: true, session_token: '')
  end

  def unlock!
    update_attributes(locked: false, login_attempts: 0)
  end

  def session_heartbeat!
    update_attribute(:session_last_active, Time.current)
  end

  def password=(plaintext)
    self.password_hashed = encrypt_password(plaintext)
  end

  def encrypt_password(plaintext)
    hexdigest("#{ SALT }#{ plaintext }#{ email }#{ initial_password }")
  end

  def decrypted_rotp_secret_base
    active_support_encryptor.decrypt_and_verify(generate_rotp_secret_base!)
  end

  private

  def authentication_policy
    @authentication_policy ||= ::AdminAuthenticationPolicy.new(self)
  end

  def active_support_encryptor
    key_to_encrypt = hexdigest("#{ SALT }#{ email }#{ initial_password }")
    @encryptor ||= ActiveSupport::MessageEncryptor.new(key_to_encrypt)
  end

  def set_default_password
    self.password = initial_password if new_record? && password_hashed.blank?
  end

  def generate_rotp_secret_base!
    # each admin will have a separate key base, stored as encrypted string.
    if rotp_secret_base.blank?
      self.rotp_secret_base = active_support_encryptor.encrypt_and_sign(ROTP::Base32.random_base32)
      save!
    end
    rotp_secret_base
  end

  def hexdigest(string)
    Digest::SHA256.hexdigest(string)
  end
end
