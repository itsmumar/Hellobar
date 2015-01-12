class TrackingController < ApplicationController
  def track
    Analytics.track(params[:type], params[:id], params[:event], get_props)
    render :text=>"ok"
  end

  def track_current_person
    Analytics.track(*current_person_type_and_id, params[:event], get_props)
    render :text=>params.inspect
  end

  def pixel
    # Note: tracking happens in ApplicationController#record_tracking_param
    send_file Rails.root.join("app/assets/images", "pixel.gif"), :type => "image/gif", :disposition => "inline"
  end

  protected
  def get_props
    return nil unless params[:props]
    begin
      return JSON.parse(params[:props])
    rescue StandardError
      return nil
    end
  end
end
