class ReferralToken < ActiveRecord::Base
  belongs_to :tokenizable, polymorphic: true

  validates :token, uniqueness: true



  private

  after_initialize :generate_random_token
  def generate_random_token
    self.token ||= SecureRandom.hex
  end
end
