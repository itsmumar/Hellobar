class CreateUserFromAgency
  def initialize(params)
    @email = params[:email]
    @password = params[:password]
    @name = params[:name]
    @agency_name = params[:agency_name]
    @url = params[:url]
  end

  def call
    create_user
    create_site
    track_event
  end

  private

  attr_reader :email, :password, :name, :agency_name, :url

  def create_user
    @user = CreateUser.new(user).call
  end

  def create_site
    @site = CreateSite.new(site, @user, referral_token: '').call
    ChangeSubscription.new(site, subscription: 'ProManaged', schedule: 'monthly').call
  end

  def site
    Site.new(url: url)
  end

  def user
    @user = User.new(email: email, password: password, password_confirmation: password, first_name: name)
  end

  def track_event
    TrackEvent.new(:agency_client, site: @site, user: @user).call
  end
end
