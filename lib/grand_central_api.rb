begin
#  require 'hmac-sha1'
#  require 'hmac-sha2'
require 'openssl'

rescue LoadError
  # If they don't have this we don't want to kill everything with a load error
  # howver if you attempt to use this API it will error out
end

require 'net/http'
require 'uri'
require 'cgi'
require 'fileutils'

class GrandCentralApi
  class << self
    def request_log_path
      File.join(Rails.root, 'log', "grand-central-api_#{Rails.env}.log")
    end

    def digest
      OpenSSL::Digest::SHA512.new
    end

    def requests
      return [] unless File.exist?(request_log_path)

      data = File.read(request_log_path)
      return [] if data == ''
      Marshal.load(data)
    end

    def record_request(request)
      requests = self.requests
      requests << request
      FileUtils.mkdir_p(File.dirname(request_log_path))
      File.open(request_log_path, 'w') { |f| f.write(Marshal.dump(requests)) }
    end

    def reset_requests
      FileUtils.rm(request_log_path) if File.exist?(request_log_path)
    end
  end

  # Generic error class
  class APIError < RuntimeError
    attr_reader :code, :body
    def initialize(code, body)
      @code, @body = code, body
      super("#{@code} error - #{@body}")
    end
  end

  # Arguments:
  # - endpoint: where Grand Central is at (e.g. "http://central.cms.com")
  # - api_key: the API key for the site (available from Grand Central)
  # - secret: the secret for the site (available from Grand Central)
  def initialize(endpoint, api_key, secret)
    @endpoint = endpoint.gsub(/\/$/, '') # Remove trailing slash from endpoint
    @api_key, @secret = api_key, secret
  end

  # This sends the mail specified by mail (e.g. "Welcome")
  # to the addresses specified in data. Data is a hash where they
  # key is the email address and the value is an array of attributes
  # to be passed to Grand Central to be replaced in the mail message
  # (e.g. {"john@cms.com"=>{"first_name"=>"John"}})
  #
  # Returns a hash where the key is the email address and the value
  # is a status indicating if the mail was already sent, if there
  # was an error or if the it queued up to be sent
  def send_mail(mail, data)
    request("/api/send/#{CGI.escape(mail)}", data)
  end

  # This checks if the mail specified by mail (e.g. "Welcome")
  # has been sent to the addresses passed in data, which is simply
  # an array of email addresses (e.g. ["john@cms.com"]).
  #
  # Returns a hash where the key is the email address and the value
  # is a status indicating if the mail was already sent, if there
  # was an error or if the it queued up to be sent
  def sent_mail(mail, data)
    request("/api/sent/#{CGI.escape(mail)}", data)
  end

  protected

  def sign(timestamp, path, data)
    OpenSSL::HMAC.hexdigest(self.class.digest, @secret, [@api_key, timestamp, path, data].join('|'))
  end

  # Issues the actual request
  def request(path, data)
    if Rails.env.test?
      self.class.record_request(path: path, data: data)
      return
    end

    # Convert the data to JSON
    data = data.to_json unless data.is_a?(String)

    # Generate a new timestamp
    timestamp = Time.current.to_i

    # Path must start with a "/"
    path = '/' + path unless path =~ /^\//

    # Parse the URL
    url = URI.parse(@endpoint + path)

    # Create the request and add the headers
    request = Net::HTTP::Post.new(url.path)
    request.add_field('API-key', @api_key)
    request.add_field('API-timestamp', timestamp)
    request.add_field('API-sig', sign(timestamp, path, data))
    # Set the body to the data being sent
    request.body = data

    # Issue the request
    response = Net::HTTP.new(url.host, url.port).start do |http|
      http.request(request)
    end
    # Check the status code
    raise APIError.new(response.code, response.body) unless response.code == '200'
    JSON.parse(response.body)
  end
end

class GrandCentralAPI < GrandCentralApi
end
