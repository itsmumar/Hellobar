class CreateUser
  def initialize(user)
    @user = user
  end

  # @return User
  def call
    user.save!
    track_event
    user
  end

  private

  attr_reader :user

  def track_event
    TrackEvent.new(:signed_up, user: user).call
  end
end
