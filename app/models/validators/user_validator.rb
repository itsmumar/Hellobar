# Modifies Devise Validatable to fit our needs.
# Mostly just removes email uniqueness as we have our own check in User.rb

module UserValidator
  def self.included(base)
    base.extend ClassMethods

    base.class_eval do
      validates_presence_of   :email, if: :email_required?
      validates_format_of     :email, with: email_regexp, allow_blank: true, if: :email_changed?

      validates_presence_of     :password, if: :password_required?
      validates_confirmation_of :password, if: :password_required?
      validates_length_of       :password, within: password_length, allow_blank: true
    end
  end

  protected

  # Checks whether a password is needed or not. For validations only.
  # Passwords are always required if it's a new record, or if the password
  # or confirmation are being set somewhere.
  def password_required?
    !persisted? || !password.nil? || !password_confirmation.nil?
  end

  def email_required?
    true
  end

  module ClassMethods
    Devise::Models.config(self, :email_regexp, :password_length)
  end
end
