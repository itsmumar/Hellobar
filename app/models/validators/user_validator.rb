# Modifies Devise Validatable to fit our needs.
# Mostly just removes email uniqueness as we have our own check in User.rb

module UserValidator
  def self.included(base)
    base.extend ClassMethods

    base.class_eval do
      validates :email, presence: { if: :email_required? }
      validates :email, format: { with: email_regexp, allow_blank: true, if: :email_changed? }

      validates :password, presence: { if: :password_required? }
      validates :password, confirmation: { if: :password_required? }
      validates :password, length: { within: password_length, allow_blank: true }
    end
  end

  protected

  # Checks whether a password is needed or not. For validations only.
  # Passwords are always required if it's a new record, or if the password
  # or confirmation are being set somewhere.
  def password_required?
    !persisted? || password.present? || password_confirmation.present?
  end

  def email_required?
    true
  end

  module ClassMethods
    Devise::Models.config(self, :email_regexp, :password_length)
  end
end
