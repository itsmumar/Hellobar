class Admin < ActiveRecord::Base
  LOCKDOWN_KEY_EXPIRY = 2.hours
  MAX_ACCESS_TOKENS = 10
  MAX_LOGIN_ATTEMPTS = 4
  MAX_SESSION_TIME = 4.hours
  MAX_TIME_BEFORE_NEEDS_NEW_PASSWORD = 90.days
  MAX_TIME_TO_VALIDATE_ACCESS_TOKEN = 15.minutes
  MIN_PASSWORD_LENGTH = 8
  SALT = 'thisismyawesomesaltgoducks'
  ISSUER = 'HelloBar'

  include Rails.application.routes.url_helpers

  validates :password_hashed, presence: true

  before_validation :set_default_password, on: :create

  after_create :generate_rotp_secret_base!

  serialize :valid_access_tokens, Hash

  class << self
    def make(email, initial_password)
      Admin.new(:email => email, :initial_password => initial_password)
    end

    def make!(email, initial_password)
      make(email, initial_password).tap(&:save!)
    end

    def validate_session(access_token, token)
      if admin = Admin.where(:session_access_token => access_token, :session_token => token).first
        if Time.now - admin.session_last_active > MAX_SESSION_TIME
          return nil
        else
          admin.session_heartbeat!
        end

        return nil if admin.locked?
      end

      return admin
    end

    def any_validated_access_token?(access_token)
      Admin.all.any? { |a| a.has_validated_access_token?(access_token) }
    end

    def record_login_attempt(email, ip, user_agent, access_cookie)
      AdminLoginAttempt.create!(
        :email => email,
        :ip_address => ip,
        :user_agent => user_agent,
        :access_cookie => access_cookie,
        :attempted_at => Time.current
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
      Admin.all.each(&:lock!)
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

  # Sends an email that includes a validate link for the given access_token. The email
  # has a key that is a combination of the access_token, email and the timestamp
  def send_validate_access_token_email!(access_token)
    timestamp = Time.now.to_i

    validate_url = admin_validate_access_token_url(email: email, key: access_token_key(access_token, timestamp), timestamp: timestamp, host: Hellobar::Settings[:host])
    lockdown_url = admin_lockdown_url(email: email, key: Admin.lockdown_key(email, timestamp), timestamp: timestamp, host: Hellobar::Settings[:host])

    Pony.mail({
        :to => email,
        :subject => 'Admin login attempt',
        :body => "Someone is attempting to log into your admin account from an unrecognized computer.

If this is you, click this link to continue logging in:

        It's me let me in -> #{validate_url}

If this is not you, this may be an attack and you should lock down the admin by clicking this link:

        Not me, lock it down -> #{lockdown_url}

"
    })
  end

  # If they key is valid for the access_token, email and timestamp and the timestamp is within
  # MAX_TIME_TO_VALIDATE_ACCESS_TOKEN then we validate the access_token and return true (otherwise false)
  # IF true, this will also add the access_token the list of valid access_token addresses
  def validate_access_token(access_token, key, timestamp)
    if access_token_key(access_token, timestamp) == key and Time.now.to_i - timestamp < MAX_TIME_TO_VALIDATE_ACCESS_TOKEN
      set_valid_access_token(access_token, nil)
      return true
    else
      return false
    end
  end

  # Sets the timestamp for when the last successful login of an access_token was
  # The timestamp can also be nil for a newly validated access_token that has not
  # been logged in from yet
  def set_valid_access_token(access_token, last_successful_login)
    updated_access_tokens = valid_access_tokens.merge(access_token => [Time.now.to_i, last_successful_login])

    # If we have reached our limit sort by the most recent first
    # and remove any over the limit
    if updated_access_tokens.length > MAX_ACCESS_TOKENS
      access_token_list = []

      # First build an array of access tokens with a sortable field
      updated_access_tokens.each do |access_token, timestamps|
        most_recent_timestamp = timestamps.collect(&:to_i).max
        access_token_list << [access_token, most_recent_timestamp, timestamps]
      end

      # Only store the most recent access tokens
      updated_access_tokens = {}
      access_token_list.sort { |a, b| b[1] <=> a[1] }[0..MAX_ACCESS_TOKENS].each do |data|
        updated_access_tokens[data[0]] = data[2]
      end
    end

    update_attribute(:valid_access_tokens, updated_access_tokens)
  end

  # Validates the access_token, password and otp_code
  # Makes sure not locked
  # Save entered_otp, so next time user won't see the barcode rendered again.
  # Also increases the login_attempts and locks it down if reaches MAX_LOGIN_ATTEMPTS
  # If this is a valid login then we call login!. Returns true if everything
  # is valid, false otherwise
  def validate_login(access_token, password, entered_otp)
    update_attribute(:login_attempts, login_attempts + 1)
    update_attribute(:authentication_code, entered_otp)

    lock! if login_attempts > MAX_LOGIN_ATTEMPTS

    return false if locked? ||
                    !valid_authentication_otp?(entered_otp) ||
                    password_hashed != encrypt_password(password) ||
                    !has_validated_access_token?(access_token)

    login!(access_token)
    return true
  end

  def valid_authentication_otp?(otp)
    authentication_policy.otp_valid?(otp)
  end

  def reset_password!(unencrypted_password)
    timestamp = Time.now
    update_attribute(:password_last_reset, timestamp)
    set_password!(unencrypted_password)

    lockdown_url = admin_lockdown_url(:email => email, :key => Admin.lockdown_key(email, timestamp.to_i), :timestamp => timestamp.to_i, :host => Hellobar::Settings[:host])

    Pony.mail({
        :to => email,
        :subject => 'Your password has been reset',
        :body => "If this is not you, this may be an attack and you should lock down the admin by clicking this link:

        Not me, lock it down -> #{lockdown_url}

"
    })
  end

  # Reset login_attempts, and set session_access_token, session_token,
  # and session_last_active
  def login!(access_token)
    return false if locked?

    now = Time.now.to_i
    update_attributes(
      :login_attempts => 0,
      :session_token => Digest::SHA256.hexdigest([now, rand(10_000), access_token, email, rand(10_000)].collect(&:to_s).join('')),
      :session_access_token => access_token
    )
    set_valid_access_token(access_token, now)
    session_heartbeat!
  end

  def needs_to_set_new_password?
    !password_last_reset || Time.now - password_last_reset > MAX_TIME_BEFORE_NEEDS_NEW_PASSWORD
  end

  def lock!
    update_attributes(:locked => true, :session_token => '')
  end

  def unlock!
    update_attributes(locked: false, login_attempts: 0)
  end

  def has_validated_access_token?(access_token)
    valid_access_tokens.has_key?(access_token)
  end

  def session_heartbeat!
    update_attribute(:session_last_active, Time.now)
  end

  def set_password(plaintext)
    self.password_hashed = encrypt_password(plaintext)
  end

  def set_password!(plaintext)
    set_password(plaintext)
    save!
  end

  def encrypt_password(plaintext)
    Digest::SHA256.hexdigest("#{SALT}#{plaintext}#{email}#{initial_password}")
  end

  def access_token_key(token, timestamp)
    Digest::SHA256.hexdigest(['validate_access_token', email, token, timestamp, 'a6b3b'].join)
  end

  def decrypted_rotp_secret_base
    active_support_encryptor.decrypt_and_verify(generate_rotp_secret_base!)
  end

  private

  def authentication_policy
    @authentication_policy ||= ::AdminAuthenticationPolicy.new(self)
  end

  def active_support_encryptor
    key_to_encrypt = Digest::SHA256.hexdigest("#{SALT}#{email}#{initial_password}")
    @encryptor ||= ActiveSupport::MessageEncryptor.new(key_to_encrypt)
  end

  def set_default_password
    set_password(initial_password) if new_record? && password_hashed.blank?
  end

  def generate_rotp_secret_base!
    # each admin will have a separate key base, stored as encrypted string.
    if rotp_secret_base.blank?
      self.rotp_secret_base = active_support_encryptor.encrypt_and_sign(ROTP::Base32.random_base32)
      save!
    end
    rotp_secret_base
  end
end
