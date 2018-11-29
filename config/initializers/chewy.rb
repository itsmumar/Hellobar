require 'faraday_middleware'
require 'faraday_middleware/aws_sigv4'

# this is a workaround
# chewy doesn't work out of the box for some reason
faraday_client = Elasticsearch::Transport::Transport::HTTP::Faraday.new(
  options: {
    transport_options: {
      headers: { content_type: 'application/json' }
    }
  },
  hosts: [
    {
      host: URI(Settings.elastic_search_endpoint).host,
      port: URI(Settings.elastic_search_endpoint).port,
      scheme: URI(Settings.elastic_search_endpoint).scheme
    }
  ]
)
client = Elasticsearch::Client.new
client.transport = faraday_client
Thread.current[:chewy_client] = client

Chewy.settings = {
  host: Settings.elastic_search_endpoint,
  prefix: Rails.env
}
