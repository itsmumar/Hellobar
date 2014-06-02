class SitesController < ApplicationController
  layout "with_sidebar"
  before_filter :authenticate_user!
end
