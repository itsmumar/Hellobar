class ProxyController < ApplicationController
  def proxy
    return render(text: 'ok') if Rails.env.test?

    body = Net::HTTP.get(proxy_url)
    send_data body, disposition: :inline, type: 'image/png', filename: 'image.png'
  end

  private

  def proxy_url
    URI.parse(params[:scheme] + '://' + params[:url] + '/?' + request.env['QUERY_STRING'])
  end
end
