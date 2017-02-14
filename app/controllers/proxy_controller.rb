class ProxyController < ApplicationController

  def proxy
    if Rails.env.production? || Rails.env.development?
      result = Net::HTTP.get_response(proxy_url)
      send_data result.body, disposition: :inline, type: 'image/png', filename: 'image.png'
    else
      render text: "ok"
    end
  end

  private

  def proxy_url
    URI.parse(params[:scheme] + '://' + params[:url] + '/?' + request.env['QUERY_STRING'])
  end

end
