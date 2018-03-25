class HeartbeatController < ApplicationController
  skip_after_action :store_last_requested_path

  def index
    string = '<h1>Request Headers</h1>'

    request.headers.each do |header|
      string << '<p>'
      string << header.to_s
      string << '</p>'
    end

    string << '<h1>Response Headers</h1>'
    response.headers.each do |header|
      string << '<p>'
      string << header.to_s
      string << '</p>'
    end

    render text: string
  end
end
