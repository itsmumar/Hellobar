require 'timecop'

RSpec.configure do |config|
  config.around(:each, freeze: true) do |example|
    time = example.metadata.fetch(:freeze)
    Timecop.freeze(time.eql?(true) ? Date.current : time) do
      example.run
    end
  end
end
