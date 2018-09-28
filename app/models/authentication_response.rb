class AuthenticationResponse
  attr_reader :user, :redirect_url, :provider

  def initialize(user, redirect_url, provider)
    @user = user
    @redirect_url = redirect_url
    @provider = provider
  end

  def event
    { category: 'Signup', action: 'signup-google' } if provider == 'google_oauth2'
    { category: 'Signup', action: 'signup-subscribers' } if provider == 'subscribers'
  end

  def new_user?
    user.new?
  end
end
