class Admin < ActiveRecord::Base
  LOCKDOWN_KEY_EXPIRY = 2.hours
  MAX_ACCESS_TOKENS = 10
  MAX_LOGIN_ATTEMPTS = 4
  MAX_MOBILE_CODES = 6
  MAX_SESSION_TIME = 4.hours
  MAX_TIME_BEFORE_NEEDS_NEW_PASSWORD = 90.days
  MAX_TIME_TO_VALIDATE_ACCESS_TOKEN = 15.minutes
  MIN_PASSWORD_LENGTH = 8
  MOBILE_CODE_DIGITS = 6
  MOBILE_CODE_EXPIRY = 1.day
  SALT = "thisismyawesomesaltgoducks"

  include Rails.application.routes.url_helpers

  validates :mobile_phone, format: /\+1\d{10}/
  validates :password_hashed, presence: true

  before_validation :standardize_mobile_phone, :set_default_password, on: :create

  serialize :valid_access_tokens, Hash

  class << self
    def make(email, mobile_phone)
      Admin.new(:email => email, :mobile_phone => mobile_phone)
    end

    def make!(email, mobile_phone)
      make(email, mobile_phone).tap{|a| a.save!}
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
      Admin.all.any?{|a| a.has_validated_access_token?(access_token)}
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
      Digest::SHA256.hexdigest(["lockdown", email, timestamp, "lockitnow"].join(""))
    end

    # Locks all admins
    def lockdown!
      Admin.all.each{|a| a.lock!}
    end

    def unlock_all!
      Admin.update_all("login_attempts=0, locked=0, mobile_codes_sent=0")
    end
  end

  def logout!
    update_attribute(:session_token, "")
  end

  # Returns true if we have never successfully logged in from this access_token or it has
  # been more than MAX_TIME_FOR_MOBILE_CODE since you have
  def needs_mobile_code?(access_token)
    token = valid_access_tokens[access_token]
    token.nil? || token[1].nil? || (Time.now.to_i - token[1]) > MOBILE_CODE_EXPIRY
  end

  # Creates a new MOBILE_CODE_DIGITS-digit mobile code, saves it and sends it as a text message
  # Also increments mobile_codes_sent. If that reaches MAX_MOBILE_CODES then the
  # admin gets locked
  def send_new_mobile_code!
    return false if locked?

    self.mobile_codes_sent += 1

    if mobile_codes_sent > MAX_MOBILE_CODES
      lock!
      return false
    end

    # Create the mobile code
    self.mobile_code = rand.to_s[2..(MOBILE_CODE_DIGITS + 1)]

    # Send the SMS
    Twilio::REST::Client.new(Hellobar::Settings[:twilio_user], Hellobar::Settings[:twilio_password]).account.sms.messages.create(
      :body => "Access code: #{mobile_code}",
      :to => mobile_phone,
      :from => "+14157952691"
    )

    save!
  end

  # Sends an email that includes a validate link for the given access_token. The email
  # has a key that is a combination of the access_token, email and the timestamp
  def send_validate_access_token_email!(access_token)
    timestamp = Time.now.to_i

    validate_url = admin_validate_access_token_url(email: self.email, key: access_token_key(access_token, timestamp), timestamp: timestamp, host: Hellobar::Settings[:host])
    lockdown_url = admin_lockdown_url(email: self.email, key: Admin.lockdown_key(email, timestamp), timestamp: timestamp, host: Hellobar::Settings[:host])

    Pony.mail({
        :to => email,
        :subject => "Admin login attempt",
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
        most_recent_timestamp = timestamps.collect{|t| t.to_i}.max
        access_token_list << [access_token, most_recent_timestamp, timestamps]
      end

      # Only store the most recent access tokens
      updated_access_tokens = {}
      access_token_list.sort{|a, b| b[1] <=> a[1]}[0..MAX_ACCESS_TOKENS].each do |data|
        updated_access_tokens[data[0]] = data[2]
      end
    end

    update_attribute(:valid_access_tokens, updated_access_tokens)
  end

  # Validates the access_token, password and mobile_code (which might not be required)
  # Makes sure not locked
  # Also increases the login_attempts and locks it down if reaches MAX_LOGIN_ATTEMPTS
  # If this is a valid login then we call login!. Returns true if everything
  # is valid, false otherwise
  def validate_login(access_token, password, mobile_code)
    update_attribute(:login_attempts, login_attempts + 1)

    lock! if login_attempts > MAX_LOGIN_ATTEMPTS

    if locked? ||
        (needs_mobile_code?(access_token) && mobile_code != self.mobile_code) ||
        password_hashed != encrypt_password(password) ||
        !has_validated_access_token?(access_token)

      return false
    else
      login!(access_token)
      return true
    end
  end

  def reset_password!(unencrypted_password)
    timestamp = Time.now
    update_attribute(:password_last_reset, timestamp)
    set_password!(unencrypted_password)

    lockdown_url = admin_lockdown_url(:email => email, :key => Admin.lockdown_key(email, timestamp.to_i), :timestamp => timestamp.to_i, :host => Hellobar::Settings[:host])

    Pony.mail({
        :to => email,
        :subject => "Your password has been reset",
        :body => "If this is not you, this may be an attack and you should lock down the admin by clicking this link:

        Not me, lock it down -> #{lockdown_url}

"
    })
  end

  # Reset mobile_codes_sent, login_attempts, and set session_access_token, session_token,
  # and session_last_active
  def login!(access_token)
    return false if locked?

    now = Time.now.to_i
    update_attributes(
      :mobile_codes_sent => 0,
      :login_attempts => 0,
      :session_token => Digest::SHA256.hexdigest([now, rand(10_000), access_token, self.email, rand(10_000)].collect{|t| t.to_s}.join("")),
      :session_access_token => access_token
    )
    set_valid_access_token(access_token, now)
    session_heartbeat!
  end

  def needs_to_set_new_password?
    !password_last_reset || Time.now - password_last_reset > MAX_TIME_BEFORE_NEEDS_NEW_PASSWORD
  end

  def lock!
    update_attributes(:locked => true, :session_token => "")
  end

  def unlock!
    update_attribute(:locked, false)
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
    Digest::SHA256.hexdigest("#{SALT}#{plaintext}#{email}#{mobile_phone}")
  end

  def access_token_key(token, timestamp)
    Digest::SHA256.hexdigest(["validate_access_token", email, token, timestamp, "a6b3b"].join)
  end


  private

  def standardize_mobile_phone
    return if mobile_phone.try :match, /^\+/
    self.mobile_phone = mobile_phone.gsub(/\D/,"")
    self.mobile_phone = "1#{mobile_phone}" unless mobile_code =~ /^1|\+/
    self.mobile_phone = "+#{mobile_phone}" unless mobile_code =~ /^\+/
  end

  def set_default_password
    set_password(mobile_phone) if new_record? && password_hashed.blank?
  end
end
