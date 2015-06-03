class ProxyController < ApplicationController
  def proxy
    result = Net::HTTP.get_response(proxy_url)
    send_data result.body, disposition: :inline, type: 'image/png', filename: 'image.png'
  end

  private

  def proxy_url
    URI.parse(params[:scheme] + '://' + params[:url] + '/?' + request.env['QUERY_STRING'])
  end
end
