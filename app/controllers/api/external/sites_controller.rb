class Api::External::SitesController < Api::External::ApplicationController
  before_action -> { doorkeeper_authorize! :sites }

  def index
    render json: current_user.sites.to_a, each_serializer: ::External::SiteSerializer
  end
end
