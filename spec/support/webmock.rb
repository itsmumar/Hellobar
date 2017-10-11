require 'webmock/rspec'

module WebMockHelper
  def webmock_fixture(path)
    Rails.root.join('spec', 'fixtures', 'webmock', path).read
  end
end

RSpec.configure do |config|
  config.include WebMockHelper
end

WebMock.disable_net_connect!(allow_localhost: true)
