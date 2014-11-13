class PixelController < ApplicationController
  # tracking data is recorded in ApplicationController#record_tracker

  def show
    send_file Rails.root.join("app/assets/images", "pixel.gif"), :type => "image/gif", :disposition => "inline"
  end
end
