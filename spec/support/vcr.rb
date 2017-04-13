VCR.configure do |c|
  c.ignore_localhost = true
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock
  c.default_cassette_options = { record: :once }

  c.default_cassette_options = {
    match_requests_on: [
      :method,
      VCR.request_matchers.uri_without_param(:oauth_timestamp, :oauth_nonce, :oauth_signature, :oauth_signature_method)
    ]
  }
end

RSpec.configure do |config|
  config.around(:each, :vcr) do |example|
    description = example.metadata.fetch(:example_group, example.metadata)[:full_description]
    name = description.split(/\s+/, 2).join('/').underscore.strip.gsub(/[^\w\/]+/, '_')
    name = example.metadata[:vcr].is_a?(String) ? example.metadata[:vcr] : name

    VCR.use_cassette(name) do
      example.run
    end
  end
end
