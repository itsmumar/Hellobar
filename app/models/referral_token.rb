class ReferralToken < ActiveRecord::Base
  belongs_to :tokenizable, polymorphic: true

  validates :token, uniqueness: true

  def belongs_to_a?(klass)
    tokenizable.is_a?(klass)
  end

  private

  after_initialize :generate_random_token
  def generate_random_token
    self.token ||= SecureRandom.hex
  end
end
