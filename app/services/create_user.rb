class CreateUser
  def initialize(user, cookies = {})
    @user = user
    @cookies = cookies
  end

  # @return User
  def call
    persist_user
    create_affiliate_information
    track_event
    user
  end

  private

  attr_reader :user, :cookies

  def persist_user
    user.save!
  end

  def create_affiliate_information
    CreateAffiliateInformation.new(user, cookies).call
  end

  def track_event
    TrackEvent.new(:signed_up, user: user).call
  end
end
